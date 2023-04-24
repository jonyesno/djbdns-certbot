#!/usr/bin/env bats

# shellcheck shell=sh

setup() {
  DIR=$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )
  load "${DIR}/helper"
  _setup
  PROG="${DIR}/../server/manage-certbot-records"
}

teardown() {
  _teardown
}

@test "mandatory domain argument" {
  run env \
    bash "${PROG}"
  assert_failure
  assert_output --partial 'usage:'
}

@test "checks auto directory exists" {
  run env \
    TINYDNS_ROOT="${TEST_TINYDNS_ROOT}" \
    bash "${PROG}" foo.com

  assert_failure
  assert_output --partial "FATAL no ${TEST_TINYDNS_ROOT}/auto here, bailing"

  mkdir -p "${TEST_TINYDNS_ROOT}/auto"
  run env \
    TINYDNS_ROOT="${TEST_TINYDNS_ROOT}" \
    bash "${PROG}" "${BATS_TEST_NUMBER}.foo.com" "${BATS_TEST_NUMBER}.xyz"

  assert_success
}

@test "creates validation record" {
  mkdir -p "${TEST_TINYDNS_ROOT}/auto"
  DOMAIN="${BATS_TEST_NUMBER}.foo.com"
  RECORD="${BATS_TEST_NUMBER}.xyz"
  run env \
    TINYDNS_ROOT="${TEST_TINYDNS_ROOT}" \
    bash "${PROG}" "${DOMAIN}" "${RECORD}"

  assert_success
  assert [ -f "${TEST_TINYDNS_ROOT}/auto/${DOMAIN}.certbot" ]
  assert grep -q "'_acme-challenge.${DOMAIN}:${RECORD}:60" "${TEST_TINYDNS_ROOT}/auto/${DOMAIN}.certbot"
}

@test "removes validation record" {
  mkdir -p "${TEST_TINYDNS_ROOT}/auto"
  DOMAIN="${BATS_TEST_NUMBER}.foo.com"
  RECORD="${BATS_TEST_NUMBER}.xyz"
  run env \
    TINYDNS_ROOT="${TEST_TINYDNS_ROOT}" \
    bash "${PROG}" "${DOMAIN}" "${RECORD}"

  assert_success
  assert [ -f "${TEST_TINYDNS_ROOT}/auto/${DOMAIN}.certbot" ]

  run env \
    TINYDNS_ROOT="${TEST_TINYDNS_ROOT}" \
    bash "${PROG}" "${DOMAIN}"

  assert_success
  assert [ ! -f "${TEST_TINYDNS_ROOT}/auto/${DOMAIN}.certbot" ]
}
