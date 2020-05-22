#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

#ifndef __APPLE__
#define _Nonnull
#define _Nullable
#endif

// Rust FFI required types

typedef struct rust_bool_s {
    uint8_t internal_value;
} rust_bool_t;

typedef uintptr_t rust_usize_t;

typedef struct rust_slice_s {
    void *_Nullable data;
    rust_usize_t len;
} rust_slice_t;

#define ERR_CALLBACK void (*_Nonnull exception)(void *_Nullable, rust_usize_t)

// MARK: Prefix functions

extern void *_Nullable
pahkat_prefix_package_store_create(rust_slice_t path, ERR_CALLBACK);

extern void *_Nullable
pahkat_prefix_package_store_open(rust_slice_t path, ERR_CALLBACK);

extern int8_t
pahkat_prefix_package_store_status(const void *_Nonnull handle,
                                   rust_slice_t package_key,
                                   ERR_CALLBACK);

extern rust_slice_t
pahkat_prefix_package_store_all_statuses(const void *_Nonnull handle,
                                         rust_slice_t repo_record,
                                         ERR_CALLBACK);

extern const rust_slice_t
pahkat_prefix_package_store_import(const void *_Nonnull handle,
                                   rust_slice_t package_key,
                                   rust_slice_t installer_path,
                                   ERR_CALLBACK);
extern rust_slice_t
pahkat_prefix_package_store_download_url(const void *_Nonnull handle,
                                        rust_slice_t package_key,
                                        ERR_CALLBACK);


extern void pahkat_prefix_package_store_clear_cache(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_prefix_package_store_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_prefix_package_store_force_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);

extern const char *_Nullable
pahkat_prefix_package_store_repo_indexes(const void *_Nonnull handle, ERR_CALLBACK);
        
extern const void *_Nullable
pahkat_prefix_package_store_config(const void *_Nonnull handle, ERR_CALLBACK);


extern rust_slice_t
pahkat_prefix_package_store_find_package_by_key(const void *_Nonnull handle,
                                            rust_slice_t package_key,
                                            ERR_CALLBACK);

extern const void *_Nullable
pahkat_prefix_transaction_new(const void *_Nonnull handle,
                             rust_slice_t actions,
                             ERR_CALLBACK);
            
extern rust_slice_t
pahkat_prefix_transaction_actions(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_prefix_transaction_process(const void *_Nonnull handle,
                                 uint32_t tag,
                                 rust_bool_t (*_Nonnull progress)(uint32_t,
                                                                  rust_slice_t,
                                                                  uint32_t),
                                 ERR_CALLBACK);

#if TARGET_OS_OSX
// MARK: macOS functions

extern void *_Nonnull
pahkat_macos_package_store_default();

extern void *_Nullable
pahkat_macos_package_store_new(rust_slice_t path, ERR_CALLBACK);

extern void *_Nullable
pahkat_macos_package_store_load(rust_slice_t path, ERR_CALLBACK);

extern int8_t
pahkat_macos_package_store_status(const void *_Nonnull handle,
                                  rust_slice_t package_key,
                                  rust_slice_t target,
                                  ERR_CALLBACK);

extern json_str_t *_Nullable
pahkat_macos_package_store_all_statuses(const void *_Nonnull handle,
                                        rust_slice_t repo_record,
                                        rust_slice_t target,
                                        ERR_CALLBACK);

extern rust_slice_t
pahkat_macos_package_store_download(const void *_Nonnull handle,
                                    rust_slice_t package_key,
                                    rust_bool_t (*_Nonnull progress)(rust_slice_t,
                                                                     uint64_t,
                                                                     uint64_t),
                                    ERR_CALLBACK);

extern const rust_slice_t
pahkat_macos_package_store_import(const void *_Nonnull handle,
                                   rust_slice_t package_key,
                                   rust_slice_t installer_path,
                                   ERR_CALLBACK);

extern rust_slice_t
pahkat_macos_package_store_find_package_by_id(const void *_Nonnull handle,
                                              rust_slice_t package_id,
                                              ERR_CALLBACK);
extern rust_slice_t
pahkat_macos_package_store_find_package_by_key(const void *_Nonnull handle,
                                            rust_slice_t package_key,
                                            ERR_CALLBACK);

extern void pahkat_macos_package_store_clear_cache(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_macos_package_store_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_macos_package_store_force_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);

extern const char *_Nullable
pahkat_macos_package_store_repo_indexes(const void *_Nonnull handle, ERR_CALLBACK);
        
extern const void *_Nullable
pahkat_macos_package_store_config(const void *_Nonnull handle, ERR_CALLBACK);

// MARK: macOS Transaction functions

extern const void *_Nullable
pahkat_macos_transaction_new(const void *_Nonnull handle,
                             rust_slice_t actions,
                             ERR_CALLBACK);
            
extern rust_slice_t
pahkat_macos_transaction_actions(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_macos_transaction_process(const void *_Nonnull handle,
                                 uint32_t tag,
                                 rust_bool_t (*_Nonnull progress)(uint32_t,
                                                                  rust_slice_t,
                                                                  uint32_t),
                                 ERR_CALLBACK);
#endif // TARGET_OS_OSX

// MARK: Store config functions


extern rust_slice_t
pahkat_config_repos_get(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_config_repos_set(const void *_Nonnull handle, rust_slice_t repo_data, ERR_CALLBACK);

// MARK: Utility functions
extern void
pahkat_str_free(rust_slice_t ptr);

extern void
pahkat_enable_logging();

#ifdef __cplusplus
}
#endif
