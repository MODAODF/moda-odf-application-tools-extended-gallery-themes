#!/usr/bin/env bash
# Deploy environment for product development
#
# Copyright 2025 Buo-ren Lin (OSSII) <buoren.lin@ossii.com.tw>
# SPDX-License-Identifier: MIT

# Whether to disable Firewall for convenience
DISABLE_FIREWALL="${DISABLE_FIREWALL:-false}"

# Whether to disable SELinux for convenience
DISABLE_SELINUX="${DISABLE_SELINUX:-false}"

printf \
    'Info: Configuring the defensive interpreter behaviors...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to configure the defensive interpreter behaviors.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Setting the ERR trap...\n'
trap_err(){
    printf \
        'Error: The program prematurely terminated due to an unhandled error.\n' \
        1>&2
    exit 99
}
if ! trap trap_err ERR; then
    printf \
        'Error: Unable to set the ERR trap.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the existence of the required commands...\n'
required_commands=(
    realpath
)
flag_required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_required_command_check_failed=true
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Configuring the convenience variables...\n'
if test -v BASH_SOURCE; then
    # Convenience variables may not need to be referenced
    # shellcheck disable=SC2034
    {
        printf \
            'Info: Determining the absolute path of the program...\n'
        if ! script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
            )"; then
            printf \
                'Error: Unable to determine the absolute path of the program.\n' \
                1>&2
            exit 1
        fi
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
    }
fi
# Convenience variables may not need to be referenced
# shellcheck disable=SC2034
{
    script_basecommand="${0}"
    script_args=("${@}")
}

project_dir="${script_dir%/*}"

printf \
    'Info: Loading common function definitions...\n'
common_functions_file="${project_dir}/functions.sh"
# shellcheck source=../functions.sh
if ! source "${common_functions_file}"; then
    printf \
        'Error: Unable to load the common function definitions.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking runtime parameters...\n'
regex_boolean_values='^(true|false)$'
boolean_params=(
    DISABLE_FIREWALL
    DISABLE_SELINUX
)
for param in "${boolean_params[@]}"; do
    if ! [[ "${!param}" =~ ${regex_boolean_values} ]]; then
        printf \
            "Error: The %s parameter's value(%s) is invalid.\\n" \
            "${param}" \
            "${!param}" \
            1>&2
        exit 2
    fi
done

printf \
    'Info: Determining the operation timestamp...\n'
if ! operation_timestamp="$(printf '%(%Y%m%d-%H%M%S)T')"; then
    printf \
        'Error: Unable to determine the operation timestamp.\n' \
        1>&2
    exit 2
fi
printf \
    'Info: Operation timestamp determined to be "%s".\n' \
    "${operation_timestamp}"

if ! test -e /etc/os-release; then
    printf \
        'Error: Unsupported operating system.\n' \
        1>&2
    exit 1
fi

# Out of scope
# shellcheck source=/dev/null
if ! source /etc/os-release; then
    printf \
        'Error: Unable to load the os-release file.\n' \
        1>&2
    exit 2
fi

# Prevent nounset error on OS distributions that doen't set ID_LIKE(e.g. ArchLinux)
if test -z "${ID_LIKE-}"; then
    ID_LIKE=unknown
fi

required_commands=()
case "${ID_LIKE}" in
    debian)
        required_commands+=(
            # For managing Debian packages, these should already be installed
            apt-get
            dpkg
        )
    ;;
    *rhel*)
        required_commands+=(
            # For managing RPM packages, these should already be installed
            dnf
            rpm
        )
    ;;
    *)
        printf \
            'Error: Unsupported operating system category(%s).\n' \
            "${ID_LIKE}" \
            1>&2
        exit 1
    ;;
esac

printf \
    'Info: Checking the existence of the required commands...\n'
flag_required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_required_command_check_failed=true
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

if test "${EUID}" -ne 0; then
    printf \
        'Error: This program is required to be run as the superuser(root).\n' \
        1>&2
    exit 1
fi

if test "${ID_LIKE}" == debian; then
    # Avoid debconf dialogs
    export DEBIAN_FRONTEND=noninteractive

    if test "${ID}" == ubuntu \
        && ! grep -rF tw.archive.ubuntu.com /etc/apt/sources.list /etc/apt/sources.list.d; then
        printf \
            'Info: Switching Ubuntu archive server to Taiwan local mirror...\n'
        potential_source_list_files=(
            /etc/apt/sources.list
            /etc/apt/sources.list.d/ubuntu.sources
        )
        for file in "${potential_source_list_files[@]}"; do
            if ! test -e "${file}"; then
                continue
            fi

            printf \
                'Info: Patching the "%s" Ubuntu source list file...\n' \
                "${file}"
            sed_opts=(
                --in-place=".${operation_timestamp}.bak"
                --regexp-extended
                --expression='s@//([[:alnum:].]+)?archive.ubuntu.com@//tw.archive.ubuntu.com@g'
            )
            if ! sed "${sed_opts[@]}" "${file}"; then
                printf \
                    'Error: Unable to patch the "%s" Ubuntu source list file.\n' \
                    "${file}" \
                    1>&2
                exit 2
            fi
        done
    fi

    printf \
        'Info: Updating the local cache data of the APT repositories...\n'
    if ! apt-get update; then
        printf \
            'Error: Unable to update the local cache data of the APT repositories.\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Installing program runtime dependencies...\n'
runtime_dependency_pkgs=()

install_failed=false
case "${ID_LIKE}" in
    debian)
        dpkg_opts=(
            --status
        )
        if test "${#runtime_dependency_pkgs[@]}" -ne 0 \
            && ! dpkg "${dpkg_opts[@]}" "${runtime_dependency_pkgs[@]}" &>/dev/null; then
            apt_get_install_opts=(
                # Avoid installing unnecessary packages
                --no-install-recommends

                # Don't prompt for action
                -y
            )
            if ! apt-get install "${apt_get_install_opts[@]}" \
                "${runtime_dependency_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *rhel*)
        rpm_opts=(
            --query
            --quiet
        )
        if test "${#runtime_dependency_pkgs[@]}" -ne 0 \
            && ! rpm "${rpm_opts[@]}" "${runtime_dependency_pkgs[@]}"; then
            if ! dnf install -y "${runtime_dependency_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *)
        printf \
            'Error: Unsupported operating system category(%s).\n' \
            "${ID_LIKE}" \
            1>&2
        exit 1
    ;;
esac

if test "${install_failed}" == true; then
    printf \
        'Error: Unable to install program runtime dependencies.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Installing product build dependencies...\n'
build_dependency_pkgs=(
    # For extracting the extension identifier from description.xml
    xmlstarlet

    # For packing the extension files
    zip
)

install_failed=false
case "${ID_LIKE}" in
    debian)
        dpkg_opts=(
            --status
        )
        if test "${#build_dependency_pkgs[@]}" -ne 0 \
            && ! dpkg "${dpkg_opts[@]}" "${build_dependency_pkgs[@]}" &>/dev/null; then
            apt_get_install_opts=(
                # Avoid installing unnecessary packages
                --no-install-recommends

                # Don't prompt for action
                -y
            )
            if ! apt-get install "${apt_get_install_opts[@]}" \
                "${build_dependency_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *rhel*)
        rpm_opts=(
            --query
            --quiet
        )
        if test "${#build_dependency_pkgs[@]}" -ne 0 \
            && ! rpm "${rpm_opts[@]}" "${build_dependency_pkgs[@]}"; then
            if ! dnf install -y "${build_dependency_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *)
        printf \
            'Error: Unsupported operating system category(%s).\n' \
            "${ID_LIKE}" \
            1>&2
        exit 1
    ;;
esac

if test "${install_failed}" == true; then
    printf \
        'Error: Unable to install product build dependencies.\n' \
        1>&2
    exit 2
fi

if getent passwd vagrant >/dev/null; then
    printf \
        'Info: Allowing the vagrant user to access service logs...\n'
    usermod_opts=(
        # Append group ownership instead of replace
        --append
        --groups systemd-journal
    )
    if ! usermod "${usermod_opts[@]}" vagrant; then
        printf \
            'Error: Unable to allow the vagrant user to access service logs...\n' \
            1>&2
        exit 2
    fi
fi

printf \
    'Info: Installing the auxillary utilities for debugging...\n'
auxillary_utility_pkgs=(
    # For editing system and product source files
    vim
)
install_failed=false
case "${ID_LIKE}" in
    debian)
        dpkg_opts=(
            --status
        )
        if test "${#auxillary_utility_pkgs[@]}" -ne 0 \
            && ! dpkg "${dpkg_opts[@]}" "${auxillary_utility_pkgs[@]}" &>/dev/null; then
            if ! apt-get install -y "${auxillary_utility_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *rhel*)
        rpm_opts=(
            --query
            --quiet
        )
        if test "${#auxillary_utility_pkgs[@]}" -ne 0 \
            && ! rpm "${rpm_opts[@]}" "${auxillary_utility_pkgs[@]}"; then
            if ! dnf install -y "${auxillary_utility_pkgs[@]}"; then
                install_failed=true
            fi
        fi
    ;;
    *)
        printf \
            'Error: Unsupported operating system category(%s).\n' \
            "${ID_LIKE}" \
            1>&2
        exit 1
    ;;
esac

if test "${install_failed}" == true; then
    printf \
        'Error: Unable to install the auxillary utilities for debugging.\n' \
        1>&2
    exit 2
fi

if command -v getenforce >/dev/null \
    && test "${DISABLE_SELINUX}" == true; then
    if ! selinux_status="$(LANG=C getenforce)"; then
        printf \
            'Error: Unable to query SELinux status.\n' \
            1>&2
        exit 2
    fi

    if test "${selinux_status}" == Enforcing; then
        printf \
            'WARNING: Disabling SELinux for convenience...\n' \
            1>&2

        selinux_configuration_file=/etc/selinux/config

        # NOTE: In docker container this file won't exist
        if test -e "${selinux_configuration_file}"; then
            sed_opts=(
                --in-place=".orig-${operation_timestamp}"
                --regexp-extended
                --expression='s@^SELINUX=[^\n]*@SELINUX=permissive@'
            )
            if ! sed "${sed_opts[@]}" "${selinux_configuration_file}"; then
                printf \
                    'Error: Unable to patch the SELinux configuration file.\n' \
                    1>&2
                exit 2
            fi
        fi

        if ! setenforce 0; then
            printf \
                'Error: Unable to disable SELinux.\n' \
                1>&2
            exit 2
        fi
    fi
fi

if test "${ID_LIKE}" == debian \
    && command -v ufw >/dev/null; then
    printf \
        'Info: Allowing SSH incoming connections through the firewall...\n'
    if ! ufw allow ssh/tcp; then
        printf \
            'Error: Unable to allow SSH incoming connections through the firewall.\n' \
            1>&2
        exit 2
    fi

    if ! ufw_status_raw="$(LANG=C.UTF-8 ufw status)"; then
        printf \
            'Error: Unable to query the status of UFW.\n' \
            1>&2
        exit 2
    fi

    grep_opts=(
        --perl-regexp
        --regexp '(?<=^Status: ).*'
        --only-matching
    )
    if ! ufw_status="$(
        grep "${grep_opts[@]}" <<<"${ufw_status_raw}"
        )"; then
        printf \
            'Error: Unable to parse the UFW status from the output of the "ufw status" command.\n' \
            1>&2
        exit 2
    fi

    if test "${ufw_status}" != active \
        && test "${DISABLE_FIREWALL}" != true; then
        printf \
            'Info: Enabling UFW firewall...\n'
        if ! yes | ufw enable >/dev/null; then
            printf \
                'Error: Unable to enable the UFW firewall.\n' \
                1>&2
            exit 2
        fi
    fi
fi

repo_dirs=(
    "${project_dir}"
    "${project_dir}/sources/taiwan-road-traffic-signs"
)

for dir in "${repo_dirs[@]}"; do
    printf \
        "Info: Workarounding Git's \"detected dubious ownership...\" error for \"%s\" Git repository...\n" \
        "${dir}"
    if ! workaround_git_dubious_ownership_error "${dir}"; then
        printf \
            "Error: Unable to workaround Git's \"detected dubious ownership...\" error for \"%s\" Git repository.\\n" \
            "${dir}" \
            1>&2
        exit 2
    fi
done

printf \
    'Info: Operation completed without errors.\n'
