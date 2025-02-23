#!/usr/bin/env bash
##
# Adjust project repository based on user input.
#
# @usage:
# Interactive prompt:
# ./init.sh
#
# Silent:
# ./init.sh "Extension Name" extension_machine_name extension_type ci_provider command_wrapper
#
# shellcheck disable=SC2162,SC2015

set -euo pipefail
[ "${SCRIPT_DEBUG-}" = "1" ] && set -x

extension_name=${1-}
extension_machine_name=${2-}
extension_type=${3-}
ci_provider=${4-}
command_wrapper=${5-}

#-------------------------------------------------------------------------------

convert_string() {
  input_string="$1"
  conversion_type="$2"

  case "${conversion_type}" in
    "file_name" | "route_path" | "deployment_id")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
      ;;
    "domain_name" | "package_namespace")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | tr -d '-'
      ;;
    "namespace" | "class_name")
      echo "${input_string}" | tr '-' ' ' | tr '_' ' ' | awk -F" " '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));} 1' | tr -d ' -'
      ;;
    "package_name")
      echo "${input_string}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
      ;;
    "function_name" | "ui_id" | "cli_command")
      echo "${input_string}" | tr ' ' '_' | tr '[:upper:]' '[:lower:]'
      ;;
    "log_entry" | "code_comment_title")
      echo "${input_string}"
      ;;
    *)
      echo "Invalid conversion type"
      ;;
  esac
}

replace_string_content() {
  local needle="${1}"
  local replacement="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" = "Darwin" ] && sed_opts=(-i '')
  set +e
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${needle}" "$(pwd)" | xargs sed "${sed_opts[@]}" "s!$needle!$replacement!g" || true
  set -e
}

remove_string_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/^${token}/d" || true
}

remove_tokens_with_content() {
  local token="${1}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --include=".*" --include="*" --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "#;> $token" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/#;< $token/,/#;> $token/d" || true
}

uncomment_line() {
  local file_name="${1}"
  local start_string="${2}"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  LC_ALL=C.UTF-8 sed "${sed_opts[@]}" -e "s/^# ${start_string}/${start_string}/" "${file_name}"
}

remove_special_comments() {
  local token="#;"
  local sed_opts
  sed_opts=(-i) && [ "$(uname)" == "Darwin" ] && sed_opts=(-i '')
  grep -rI --exclude-dir=".git" --exclude-dir=".idea" --exclude-dir="vendor" --exclude-dir="node_modules" -l "${token}" "$(pwd)" | LC_ALL=C.UTF-8 xargs sed "${sed_opts[@]}" -e "/${token}/d" || true
}

ask() {
  local prompt="$1"
  local default="${2-}"
  local result=""

  if [[ -n $default ]]; then
    prompt="${prompt} [${default}]: "
  else
    prompt="${prompt}: "
  fi

  while [[ -z ${result} ]]; do
    read -p "${prompt}" result
    if [[ -n $default && -z ${result} ]]; then
      result="${default}"
    fi
  done
  echo "${result}"
}

ask_yesno() {
  local prompt="${1}"
  local default="${2:-Y}"
  local result

  read -p "${prompt} [$([ "${default}" = "Y" ] && echo "Y/n" || echo "y/N")]: " result
  result="$(echo "${result:-${default}}" | tr '[:upper:]' '[:lower:]')"
  echo "${result}"
}

#-------------------------------------------------------------------------------

remove_ci_provider_github_actions() {
  rm -rf .github/workflows >/dev/null 2>&1 || true
}

remove_ci_provider_circleci() {
  rm -rf .circleci >/dev/null 2>&1 || true
}

remove_command_wrapper_ahoy() {
  rm -rf .ahoy.yml >/dev/null 2>&1 || true
}

remove_command_wrapper_makefile() {
  rm -rf Makefile >/dev/null 2>&1 || true
}

process_readme() {
  mv README.dist.md "README.md" >/dev/null 2>&1 || true

  curl --silent --show-error "https://placehold.jp/000000/ffffff/200x200.png?text=${1// /+}&css=%7B%22border-radius%22%3A%22%20100px%22%7D" >logo.tmp.png || true
  if [ -s "logo.tmp.png" ]; then
    mv logo.tmp.png "logo.png" >/dev/null 2>&1 || true
  fi
  rm logo.tmp.png >/dev/null 2>&1 || true
}

process_internal() {
  local extension_name="${1}"
  local extension_machine_name="${2}"
  local extension_type="${3}"

  extension_machine_name_class="$(convert_string "${extension_machine_name}" "class_name")"

  replace_string_content "YourNamespace" "${extension_machine_name}"
  replace_string_content "yournamespace" "${extension_machine_name}"
  replace_string_content "AlexSkrypnyk" "${extension_machine_name}"
  replace_string_content "alexskrypnyk" "${extension_machine_name}"
  replace_string_content "yourproject" "${extension_machine_name}"
  replace_string_content "Yourproject logo" "${extension_name} logo"
  replace_string_content "Your Extension" "${extension_name}"
  replace_string_content "your extension" "${extension_name}"
  replace_string_content "Your+Extension" "${extension_machine_name}"
  replace_string_content "your_extension" "${extension_machine_name}"
  replace_string_content "YourExtension" "${extension_machine_name_class}"
  replace_string_content "Provides your_extension functionality." "Provides ${extension_machine_name} functionality."
  replace_string_content "drupal-module" "drupal-${extension_type}"
  replace_string_content "Drupal module scaffold FE example used for template testing" "Provides ${extension_machine_name} functionality."
  replace_string_content "Drupal extension scaffold" "${extension_name}"
  replace_string_content "drupal_extension_scaffold" "${extension_machine_name}"
  replace_string_content "type: module" "type: ${extension_type}"
  replace_string_content "\[EXTENSION_NAME\]" "${extension_machine_name}"

  remove_string_content "# Uncomment the lines below in your project."
  uncomment_line ".gitattributes" ".ahoy.yml"
  uncomment_line ".gitattributes" ".circleci"
  uncomment_line ".gitattributes" ".devtools"
  uncomment_line ".gitattributes" ".editorconfig"
  uncomment_line ".gitattributes" ".gitattributes"
  uncomment_line ".gitattributes" ".github"
  uncomment_line ".gitattributes" ".gitignore"
  uncomment_line ".gitattributes" ".skip_npm_build"
  uncomment_line ".gitattributes" ".twig-cs-fixer.php"
  uncomment_line ".gitattributes" "Makefile"
  uncomment_line ".gitattributes" "composer.dev.json"
  uncomment_line ".gitattributes" "patches"
  uncomment_line ".gitattributes" "package-lock.json"
  uncomment_line ".gitattributes" "package.json"
  uncomment_line ".gitattributes" "phpcs.xml"
  uncomment_line ".gitattributes" "phpmd.xml"
  uncomment_line ".gitattributes" "phpstan.neon"
  uncomment_line ".gitattributes" "phpunit.d10.xml"
  uncomment_line ".gitattributes" "phpunit.xml"
  uncomment_line ".gitattributes" "rector.php"
  uncomment_line ".gitattributes" "renovate.json"
  uncomment_line ".gitattributes" "tests"
  remove_string_content "# Remove the lines below in your project."
  remove_string_content ".github\/FUNDING.yml export-ignore"
  remove_string_content "LICENSE             export-ignore"

  mv "your_extension.info.yml" "${extension_machine_name}.info.yml"
  mv "your_extension.install" "${extension_machine_name}.install"
  mv "your_extension.links.menu.yml" "${extension_machine_name}.links.menu.yml"
  mv "your_extension.module" "${extension_machine_name}.module"
  mv "your_extension.routing.yml" "${extension_machine_name}.routing.yml"
  mv "your_extension.services.yml" "${extension_machine_name}.services.yml"
  mv "config/schema/your_extension.schema.yml" "config/schema/${extension_machine_name}.schema.yml"
  mv "src/Form/YourExtensionForm.php" "src/Form/${extension_machine_name_class}Form.php"
  mv "src/YourExtensionService.php" "src/${extension_machine_name_class}Service.php"
  mv "tests/src/Unit/YourExtensionServiceUnitTest.php" "tests/src/Unit/${extension_machine_name_class}ServiceUnitTest.php"
  mv "tests/src/Kernel/YourExtensionServiceKernelTest.php" "tests/src/Kernel/${extension_machine_name_class}ServiceKernelTest.php"
  mv "tests/src/Functional/YourExtensionFunctionalTest.php" "tests/src/Functional/${extension_machine_name_class}FunctionalTest.php"

  rm -f LICENSE >/dev/null || true
  rm -Rf "tests/scaffold" >/dev/null || true
  rm -f .github/workflows/scaffold*.yml >/dev/null || true
  rm -Rf .scaffold >/dev/null || true

  remove_tokens_with_content "META"
  remove_special_comments

  if [ "${extension_type}" = "theme" ]; then
    rm -rf tests >/dev/null || true
    echo 'base theme: false' >>"${extension_machine_name}.info.yml"
  fi
}

#-------------------------------------------------------------------------------

main() {
  echo "Please follow the prompts to adjust your extension configuration"
  echo

  [ -z "${extension_name}" ] && extension_name="$(ask "Name")"
  extension_machine_name_default="$(convert_string "${extension_name}" "file_name")"
  [ -z "${extension_machine_name}" ] && extension_machine_name="$(ask "Machine name" "${extension_machine_name_default}")"
  extension_type_default="module"
  [ -z "${extension_type}" ] && extension_type="$(ask "Type: module or theme" "${extension_type_default}")"
  ci_provider_default="gha"
  [ -z "${ci_provider}" ] && ci_provider="$(ask "CI Provider: GitHub Actions (gha) or CircleCI (circleci)" "${ci_provider_default}")"
  command_wrapper_default="ahoy"
  [ -z "${command_wrapper}" ] && command_wrapper="$(ask "Command wrapper: Ahoy (ahoy), Makefile (makefile), None (none)" "${command_wrapper_default}")"

  remove_self="$(ask_yesno "Remove this script")"

  echo
  echo "            Summary"
  echo "---------------------------------"
  echo "Name                             : ${extension_name}"
  echo "Machine name                     : ${extension_machine_name}"
  echo "Type                             : ${extension_type}"
  echo "CI Provider                      : ${ci_provider}"
  echo "Command wrapper                  : ${command_wrapper}"
  echo "Remove this script               : ${remove_self}"
  echo "---------------------------------"
  echo

  should_proceed="$(ask_yesno "Proceed with project init")"

  if [ "${should_proceed}" != "y" ]; then
    echo
    echo "Aborting."
    exit 1
  fi

  #
  # Processing.
  #

  : "${extension_name:?name is required}"
  : "${extension_machine_name:?machine_name is required}"
  : "${extension_type:?type is required}"
  : "${ci_provider:?ci_provider is required}"
  : "${command_wrapper:?command_wrapper is required}"

  if [ "${ci_provider}" = "circleci" ]; then
    remove_ci_provider_github_actions
  else
    remove_ci_provider_circleci
  fi

  if [ "${command_wrapper}" = "ahoy" ]; then
    remove_command_wrapper_makefile
  elif [ "${command_wrapper}" = "makefile" ]; then
    remove_command_wrapper_ahoy
  else
    remove_command_wrapper_ahoy
    remove_command_wrapper_makefile
  fi

  process_readme "${extension_name}"

  process_internal "${extension_name}" "${extension_machine_name}" "${extension_type}" "${ci_provider}"

  [ "${remove_self}" != "n" ] && rm -- "$0" || true

  echo
  echo "Initialization complete."
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
fi
