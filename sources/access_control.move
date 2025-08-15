// module aptos_tutorial::access_control {
//     use std::signer;
//     use std::vector;
//     use std::error;
//     use aptos_framework::ordered_map::{Self, OrderedMap};
//     use aptos_framework::object::{Self, ObjectCore};
//     use aptos_framework::event;
//     use aptos_framework::timestamp::now_seconds;

//     // -- Roles
//     // ADMIN can change system configurations
//     const ROLE_ADMIN: u8 = 1;
//     // ROLE_MANAGER can add/remove account (registry must be unlocked by ADMIN first)
//     const ROLE_ROLE_MANAGER: u8 = 2;
//     // SERVICE_ACCOUNT can deposit/withdraw fund to/from strategy
//     const ROLE_SERVICE_ACCOUNT: u8 = 3;
//     // FEE_MANAGER can config fee, withdraw fee
//     const ROLE_FEE_MANAGER: u8 = 4;

//     // IMPORTANT: increse this value when add/remove role
//     const ROLE_COUNT: u8 = 4;

//     // -- Error Codes
//     const E_ALREADY_INITIALIZED: u64 = 1;
//     const E_NOT_AUTHORIZED: u64 = 2;
//     const E_EMPTY_ROLES: u64 = 3;
//     const E_ACCOUNT_CANNOT_BE_REMOVED: u64 = 4;
//     const E_CONFLICT_ROLES: u64 = 5;
//     const E_REGISTRY_LOCKED: u64 = 6;

//     // -- Structs
//     struct Registry has key {
//         accounts: OrderedMap<address, vector<u8>>,
//         locked_at: u64
//     }

//     struct AccountItem has drop {
//         account: address,
//         roles: vector<u8>
//     }

//     //-- Event
//     #[event]
//     struct UpdateAccountEvent has drop, store {
//         account: address,
//         roles: vector<u8>,
//         timestamp: u64
//     }

//     #[event]
//     struct RemoveAccountEvent has drop, store {
//         account: address,
//         timestamp: u64
//     }

//     fun init_module(sender: &signer) {
//         let addr = signer::address_of(sender);
//         assert!(
//             !exists<Registry>(addr),
//             error::already_exists(E_ALREADY_INITIALIZED)
//         );

//         let admin_addr =
//             if (object::is_object(addr)) {
//                 object::root_owner(object::address_to_object<ObjectCore>(addr))
//             } else { addr };

//         let accounts = ordered_map::new<address, vector<u8>>();
//         ordered_map::add(
//             &mut accounts,
//             admin_addr,
//             vector[ROLE_ADMIN, ROLE_FEE_MANAGER]
//         );

//         move_to(sender, Registry { accounts, locked_at: now_seconds() + 600 });
//     }

//     // -- Entries

//     public entry fun unlock_registry(sender: &signer, timeout: u64) acquires Registry {
//         must_be_admin(sender);

//         let registry = borrow_global_mut<Registry>(@aptos_tutorial);
//         registry.locked_at = now_seconds() + timeout;
//     }

//     public entry fun upsert_account(
//         sender: &signer, account: address, roles: vector<u8>
//     ) acquires Registry {
//         let addr = signer::address_of(sender);
//         let registry = borrow_global_mut<Registry>(@aptos_tutorial);
//         let count = registry.count_role(ROLE_ROLE_MANAGER);
//         if (count == 0) {
//             // allow admin to add the first role manager
//             assert!(
//                 registry.has_role(&addr, ROLE_ADMIN),
//                 error::permission_denied(E_NOT_AUTHORIZED)
//             )
//         } else {
//             assert!(
//                 registry.has_role(&addr, ROLE_ROLE_MANAGER),
//                 error::permission_denied(E_NOT_AUTHORIZED)
//             )
//         };

//         // TODO: remove duplicated values
//         let valid_roles = vector::filter(roles, |v| *v <= ROLE_COUNT);
//         assert!(
//             !vector::is_empty(&valid_roles), error::invalid_argument(E_EMPTY_ROLES)
//         );

//         let is_admin = vector::contains(&valid_roles, &ROLE_ADMIN);
//         let is_manager = vector::contains(&valid_roles, &ROLE_ROLE_MANAGER);
//         assert!(!is_admin || !is_manager, error::permission_denied(E_CONFLICT_ROLES));

//         ensure_registry_is_unlocked(registry);

//         ordered_map::upsert(&mut registry.accounts, account, valid_roles);

//         event::emit(UpdateAccountEvent { account, roles, timestamp: now_seconds() });
//     }

//     public entry fun remove_account(sender: &signer, account: address) acquires Registry {
//         must_be_role_manager(sender);

//         let registry = borrow_global_mut<Registry>(@aptos_tutorial);
//         ensure_registry_is_unlocked(registry);
//         assert!(ordered_map::contains(&registry.accounts, &account));
//         ensure_account_is_safe_to_remove(registry, &account);

//         ordered_map::remove(&mut registry.accounts, &account);

//         event::emit(RemoveAccountEvent { account, timestamp: now_seconds() });
//     }

//     // -- Views

//     #[view]
//     public fun get_accounts(): vector<AccountItem> acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         let keys = ordered_map::keys(&registry.accounts);
//         vector::map_ref(
//             &keys,
//             |k| {
//                 let roles = ordered_map::borrow(&registry.accounts, k);
//                 AccountItem { account: *k, roles: *roles }
//             }
//         )
//     }

//     // -- Public

//     public fun must_be_admin(sender: &signer) acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         let addr = signer::address_of(sender);
//         assert!(
//             registry.has_role(&addr, ROLE_ADMIN),
//             error::permission_denied(E_NOT_AUTHORIZED)
//         )
//     }

//     public fun must_be_role_manager(sender: &signer) acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         let addr = signer::address_of(sender);
//         assert!(
//             registry.has_role(&addr, ROLE_ROLE_MANAGER),
//             error::permission_denied(E_NOT_AUTHORIZED)
//         )
//     }

//     public fun must_be_service_account(sender: &signer) acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         let addr = signer::address_of(sender);
//         assert!(
//             registry.has_role(&addr, ROLE_SERVICE_ACCOUNT),
//             error::permission_denied(E_NOT_AUTHORIZED)
//         )
//     }

//     public fun must_be_fee_manager(sender: &signer) acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         let addr = signer::address_of(sender);
//         assert!(
//             registry.has_role(&addr, ROLE_FEE_MANAGER),
//             error::permission_denied(E_NOT_AUTHORIZED)
//         )
//     }

//     // -- Private

//     fun has_role(self: &Registry, addr: &address, role: u8): bool {
//         if (ordered_map::contains(&self.accounts, addr)) {
//             let roles = ordered_map::borrow(&self.accounts, addr);
//             vector::contains(roles, &role)
//         } else { false }
//     }

//     fun count_role(self: &Registry, role: u8): u8 {
//         let n = 0;
//         let values = ordered_map::values(&self.accounts);
//         vector::for_each_ref(
//             &values,
//             |v| {
//                 if (vector::contains(v, &role)) {
//                     n = n + 1;
//                 }
//             }
//         );
//         n
//     }

//     fun ensure_account_is_safe_to_remove(
//         registry: &Registry, account: &address
//     ) {
//         if (has_role(registry, account, ROLE_ADMIN)) {
//             let count = registry.count_role(ROLE_ADMIN);
//             assert!(count > 1, error::permission_denied(E_ACCOUNT_CANNOT_BE_REMOVED));
//         };

//         if (has_role(registry, account, ROLE_ROLE_MANAGER)) {
//             let count = registry.count_role(ROLE_ROLE_MANAGER);
//             assert!(count > 1, error::permission_denied(E_ACCOUNT_CANNOT_BE_REMOVED));
//         }
//     }

//     fun ensure_registry_is_unlocked(registry: &Registry) {
//         assert!(
//             registry.locked_at > now_seconds(),
//             error::permission_denied(E_REGISTRY_LOCKED)
//         )
//     }

//     // -- test only
//     #[test_only]
//     public fun init_module_for_testing(sender: &signer) {
//         init_module(sender)
//     }
// }
