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

// MARK: Rust FFI required types

typedef uint8_t rust_bool_t;
typedef uintptr_t rust_usize_t;

typedef struct rust_slice_s {
    void *_Nullable data;
    uintptr_t len;
} rust_slice_t;

#if _WIN32
typedef wchar_t rust_path_t;
#else
typedef char rust_path_t;
#endif

#define ERR_CALLBACK void (*_Nonnull exception)(const char *_Nonnull)

// MARK: Pahkat structs

typedef struct package_status_s {
    rust_bool_t is_system;
    int8_t status;
} package_status_t;

typedef char json_str_t;

// MARK: Prefix functions

extern void *_Nullable
pahkat_prefix_package_store_create(const rust_path_t *_Nonnull path, ERR_CALLBACK);

extern void *_Nullable
pahkat_prefix_package_store_open(const rust_path_t *_Nonnull path, ERR_CALLBACK);

extern package_status_t
pahkat_prefix_package_store_status(const void *_Nonnull handle, const char *_Nonnull package_key, ERR_CALLBACK);

extern json_str_t *_Nullable
pahkat_prefix_package_store_all_statuses(const void *_Nonnull handle,
                                         const json_str_t *_Nonnull repo_record,
                                         ERR_CALLBACK);
extern const rust_path_t *_Nullable
pahkat_prefix_package_store_import(const void *_Nonnull handle, const char *_Nonnull package_key, const rust_path_t *_Nonnull installer_path, ERR_CALLBACK);

extern void pahkat_prefix_package_store_clear_cache(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_prefix_package_store_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);
extern void pahkat_prefix_package_store_force_refresh_repos(const void *_Nonnull handle, ERR_CALLBACK);

extern const char *_Nullable
pahkat_prefix_package_store_repo_indexes(const void *_Nonnull handle, ERR_CALLBACK);
        
extern const void *_Nullable
pahkat_prefix_package_store_config(const void *_Nonnull handle, ERR_CALLBACK);


extern const json_str_t *_Nullable
pahkat_prefix_package_store_resolve_package(const void *_Nonnull handle,
                                            const char *_Nonnull package_key,
                                            ERR_CALLBACK);

extern const void *_Nullable
pahkat_prefix_transaction_new(const void *_Nonnull handle,
                             const json_str_t *_Nonnull actions,
                             ERR_CALLBACK);
            
extern const json_str_t *_Nullable
pahkat_prefix_transaction_actions(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_prefix_transaction_process(const void *_Nonnull handle,
                                 uint32_t tag,
                                 void (*_Nonnull progress)(uint32_t, const char *_Nonnull, uint32_t),
                                 ERR_CALLBACK);

// MARK: macOS functions

extern void *_Nonnull
pahkat_macos_package_store_default();

extern void *_Nullable
pahkat_macos_package_store_new(const rust_path_t *_Nonnull path, ERR_CALLBACK);

extern void *_Nullable
pahkat_macos_package_store_load(const rust_path_t *_Nonnull path, ERR_CALLBACK);

extern package_status_t
pahkat_macos_package_store_status(const void *_Nonnull handle, const char *_Nonnull package_key, ERR_CALLBACK);

extern json_str_t *_Nullable
pahkat_macos_package_store_all_statuses(const void *_Nonnull handle,
                                         const json_str_t *_Nonnull repo_record,
                                         ERR_CALLBACK);

extern rust_path_t *_Nullable
pahkat_macos_package_store_download(const void *_Nonnull handle,
                                    const char *_Nonnull package_key,
                                    void (*_Nonnull progress)(const void *_Nonnull, uint64_t, uint64_t),
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
                             const json_str_t *_Nonnull actions,
                             ERR_CALLBACK);
            
extern const json_str_t *_Nullable
pahkat_macos_transaction_actions(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_macos_transaction_process(const void *_Nonnull handle,
                                 uint32_t tag,
                                 void (*_Nonnull progress)(uint32_t, const char *_Nonnull, uint32_t),
                                 ERR_CALLBACK);

// MARK: Store config functions

extern void
pahkat_store_config_set_ui_value(const void *_Nonnull handle, const char *_Nonnull key, const char *_Nullable value, ERR_CALLBACK);

extern const char *_Nullable
pahkat_store_config_ui_value(const void *_Nonnull handle, const char *_Nonnull key, ERR_CALLBACK);

//extern void
//pahkat_store_config_set_cache_base_path(const void *_Nonnull handle, const char *_Nullable path, ERR_CALLBACK);
//
//extern const char *_Nullable
//pahkat_store_config_cache_base_path(const void *_Nonnull handle, ERR_CALLBACK);

extern const char *_Nullable
pahkat_store_config_skipped_package(const void *_Nonnull handle, const char *_Nonnull package_key, ERR_CALLBACK);

extern const json_str_t *_Nullable
pahkat_store_config_repos(const void *_Nonnull handle, ERR_CALLBACK);

extern void
pahkat_store_config_set_repos(const void *_Nonnull handle, const json_str_t *_Nonnull repos, ERR_CALLBACK);

// MARK: Utility functions
extern void
pahkat_str_free(const char *_Nullable ptr);

extern void
pahkat_enable_logging();

#ifdef __cplusplus
}
#endif
