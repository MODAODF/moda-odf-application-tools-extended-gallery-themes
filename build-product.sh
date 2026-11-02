#!/usr/bin/env bash
# Build product
#
# Copyright 2026 OSS Integral Institute Co., Ltd. <https://www.ossii.com.tw/contact>
# SPDX-License-Identifier: CC-BY-SA-4.0+

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
    cp
    realpath
    rm
    zip
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

if ! shopt -s nullglob; then
    printf \
        'Error: Unable to configure the nullglob shell option.\n' \
        1>&2
    exit 1
fi

project_dir="${script_dir}"

printf \
    'Info: Determining the product version...\n'
if ! version="$(
    git -C "${project_dir}" describe \
        --always \
        --dirty \
        --tags
    )"; then
    printf \
        'Error: Unable to determine the product version.\n' \
        1>&2
    exit 1
fi
version="${version#v}"
printf \
    'Info: Product version determined to be "%s".\n' \
    "${version}"

printf \
    'Info: Generating the description.xml file from template...\n'
sed_opts=(
    -e "s/__VERSION__/${version}/g"
)
if ! sed "${sed_opts[@]}" \
    "${project_dir}/description.xml.in" \
    >"${project_dir}/description.xml"; then
    printf \
        'Error: Unable to generate the description.xml file from template.\n' \
        1>&2
    exit 1
fi

taiwan_road_signs_dir="${project_dir}/sources/taiwan-road-traffic-signs"
if ! "${taiwan_road_signs_dir}/generate-gallery-files.sh" all-in-one; then
    printf \
        'Error: Unable to generate the gallery files for the Taiwan Road Traffic Signs theme.\n' \
        1>&2
    exit 1
fi

if ! cp -a "${taiwan_road_signs_dir}/gallery/taiwan-road-signs."{sdg,sdv,str,thm} "${project_dir}/gallery/"; then
    printf \
        'Error: Unable to move the generated gallery files for the Taiwan Road Traffic Signs theme.\n' \
        1>&2
    exit 1
fi

taiwan_city_county_emblems_dir="${project_dir}/sources/taiwan-city-county-emblems"
if ! "${taiwan_city_county_emblems_dir}/generate-gallery-files.sh" all-in-one; then
    printf \
        'Error: Unable to generate the gallery files of the Taiwan City and County Emblems theme.\n' \
        1>&2
    exit 1
fi

if ! cp -a "${taiwan_city_county_emblems_dir}/gallery/taiwan-city-county-emblems."{sdg,sdv,str,thm} "${project_dir}/gallery/"; then
    printf \
        'Error: Unable to move the generated gallery files of the Taiwan City and County Emblems theme to the gallery directory.\n' \
        1>&2
    exit 1
fi

taiwan_certification_markings_dir="${project_dir}/sources/taiwan-certification-markings"
if ! "${taiwan_certification_markings_dir}/generate-gallery-files.sh" all-in-one; then
    printf \
        'Error: Unable to generate the gallery files of the Taiwan Certification Markings theme.\n' \
        1>&2
    exit 1
fi

if ! cp -a "${taiwan_certification_markings_dir}/gallery/taiwan-certification-markings."{sdg,sdv,str,thm} "${project_dir}/gallery/"; then
    printf \
        'Error: Unable to move the generated gallery files of the Taiwan Certification Markings theme to the gallery directory.\n' \
        1>&2
    exit 1
fi

if ! cd "${project_dir}"; then
    printf \
        'Error: Unable to change the working directory to the project directory.\n' \
        1>&2
    exit 1
fi

if ! extension_id="$(
    xmlstarlet select \
        -N d='http://openoffice.org/extensions/description/2006' \
        -t -v '/d:description/d:identifier/@value' -n \
        "${project_dir}/description.xml"
    )"; then
    printf \
        'Error: Unable to extract the extension ID from the description.xml file.\n' \
        1>&2
    exit 1
fi

dist_release_dir="${project_dir}/dist/release"
printf \
    'Info: Ensuring the existence of the distribution release folder...\n'
if ! mkdir -p "${dist_release_dir}"; then
    printf \
        'Error: Unable to ensure the existence of the distribution release folder.\n' \
        1>&2
    exit 1
fi

built_extension="${dist_release_dir}/${extension_id}-${version}.oxt"
if ! rm -f "${built_extension}"; then
    printf \
        'Error: Unable to remove the previous extension package.\n' \
        1>&2
    exit 1
fi

zip_opts=(
    --recurse-paths
    "-i@dist-assets/zip-include.lst"
)
if ! zip "${zip_opts[@]}" \
    "${built_extension}" \
    .; then
    printf \
        'Error: Unable to create the extension package.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Successfully built the extension package "%s".\n' \
    "${built_extension}"
