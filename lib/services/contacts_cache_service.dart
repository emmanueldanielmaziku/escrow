import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';
import '../models/user_model.dart';
import 'user_service.dart';

class ContactsCacheService {
  static final ContactsCacheService _instance =
      ContactsCacheService._internal();
  factory ContactsCacheService() => _instance;
  ContactsCacheService._internal();

  final UserService _userService = UserService();

  // In-memory cache
  List<Contact>? _cachedContacts;
  Map<String, UserModel?>? _cachedEscrowUsers;
  DateTime? _lastLoadTime;
  bool _isLoading = false;
  Completer<void>? _loadingCompleter;

  // Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);

  // Getters
  List<Contact>? get cachedContacts => _cachedContacts;
  Map<String, UserModel?>? get cachedEscrowUsers => _cachedEscrowUsers;
  bool get hasCachedContacts =>
      _cachedContacts != null && _cachedContacts!.isNotEmpty;
  bool get isCacheValid =>
      _lastLoadTime != null &&
      DateTime.now().difference(_lastLoadTime!) < _cacheDuration;
  bool get isLoading => _isLoading;

  // Normalize phone number
  String _normalizePhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('255')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length >= 9) {
      return digits.substring(digits.length - 9);
    }
    return digits;
  }

  // Get phone variants for matching
  List<String> _getPhoneVariants(String normalizedPhone) {
    return [
      normalizedPhone,
      '0$normalizedPhone',
    ];
  }

  // Load contacts from device (force refresh)
  Future<void> loadContactsFromDevice({bool forceRefresh = false}) async {
    // If already loading, wait for that to complete
    if (_isLoading && _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }

    // If cache is valid and not forcing refresh, return cached data
    if (!forceRefresh && isCacheValid && hasCachedContacts) {
      return;
    }

    _isLoading = true;
    _loadingCompleter = Completer<void>();

    try {
      // Request contacts permission using flutter_contacts (shows system popup)
      final hasPermission = await FlutterContacts.requestPermission();

      if (!hasPermission) {
        // Explicitly fail when permission is not granted so UI can show a proper message
        throw Exception('Contacts permission was denied');
      }

      // Load contacts from device (optimized: only get essential properties)
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      // Filter contacts with phone numbers (no limit - load all contacts)
      final contactsWithPhones =
          contacts.where((contact) => contact.phones.isNotEmpty).toList();

      // Normalize phone numbers
      final phoneNumbers = contactsWithPhones
          .expand((contact) => contact.phones)
          .map((phone) => _normalizePhoneNumber(phone.number))
          .where((phone) => phone.length == 9)
          .toSet()
          .toList();

      // Get all phone variants for matching
      final allPhoneVariants = phoneNumbers
          .expand((phone) => _getPhoneVariants(phone))
          .toSet()
          .toList();

      // Check which contacts are in escrow (batch check)
      // Process all phone variants (no limit - we want all contacts checked)
      Map<String, UserModel?> escrowUsers = {};
      if (allPhoneVariants.isNotEmpty) {
        final limitedVariants = allPhoneVariants;

        // Batch check (Firestore whereIn limit is 10)
        final batches = <List<String>>[];
        for (var i = 0; i < limitedVariants.length; i += 10) {
          batches.add(limitedVariants.sublist(
            i,
            i + 10 > limitedVariants.length ? limitedVariants.length : i + 10,
          ));
        }

        // Process batches in parallel for faster loading (limit to 5 concurrent)
        final semaphore = <Future>[];
        for (var i = 0; i < batches.length; i++) {
          final batch = batches[i];
          final future =
              _userService.checkPhonesInEscrow(batch).then((batchResults) {
            escrowUsers.addAll(batchResults);
          });
          semaphore.add(future);

          // Limit concurrent requests to 5
          if (semaphore.length >= 5) {
            await Future.wait(semaphore);
            semaphore.clear();
          }
        }

        // Wait for remaining batches
        if (semaphore.isNotEmpty) {
          await Future.wait(semaphore);
        }

        // Map normalized phones to users found
        final normalizedToUser = <String, UserModel?>{};
        for (var normalizedPhone in phoneNumbers) {
          final variants = _getPhoneVariants(normalizedPhone);
          UserModel? foundUser;
          for (var variant in variants) {
            if (escrowUsers.containsKey(variant) &&
                escrowUsers[variant] != null) {
              foundUser = escrowUsers[variant];
              break;
            }
          }
          normalizedToUser[normalizedPhone] = foundUser;
        }
        escrowUsers = normalizedToUser;
      }

      // Update cache
      _cachedContacts = contactsWithPhones;
      _cachedEscrowUsers = escrowUsers;
      _lastLoadTime = DateTime.now();

      _isLoading = false;
      _loadingCompleter?.complete();
      _loadingCompleter = null;
    } catch (e) {
      _isLoading = false;
      _loadingCompleter?.completeError(e);
      _loadingCompleter = null;
      rethrow;
    }
  }

  // Load contacts (uses cache if available and valid)
  Future<void> loadContacts({bool forceRefresh = false}) async {
    // If cache is valid and not forcing refresh, return immediately
    if (!forceRefresh && isCacheValid && hasCachedContacts) {
      return;
    }

    // Load from device
    await loadContactsFromDevice(forceRefresh: forceRefresh);
  }

  // Load contacts in background (non-blocking)
  void loadContactsInBackground({bool forceRefresh = false}) {
    if (_isLoading) return; // Already loading

    // If cache is valid and not forcing refresh, skip
    if (!forceRefresh && isCacheValid && hasCachedContacts) {
      return;
    }

    // Start loading in background
    loadContactsFromDevice(forceRefresh: forceRefresh).catchError((error) {
      // Silently fail in background - user can retry manually
      print('Background contacts loading failed: $error');
    });
  }

  // Get contact user (from cache)
  UserModel? getContactUser(Contact contact) {
    if (_cachedEscrowUsers == null) return null;

    for (var phone in contact.phones) {
      final normalizedPhone = _normalizePhoneNumber(phone.number);
      if (normalizedPhone.length == 9) {
        return _cachedEscrowUsers![normalizedPhone];
      }
    }
    return null;
  }

  // Get contact phone (normalized)
  String getContactPhone(Contact contact) {
    if (contact.phones.isEmpty) return '';
    final normalized = _normalizePhoneNumber(contact.phones.first.number);
    return normalized.length == 9 ? normalized : '';
  }

  // Clear cache
  void clearCache() {
    _cachedContacts = null;
    _cachedEscrowUsers = null;
    _lastLoadTime = null;
  }

  // Check if we should refresh (e.g., when new contacts might be added)
  bool shouldRefresh() {
    if (!hasCachedContacts) return true;
    if (!isCacheValid) return true;
    return false;
  }

}
