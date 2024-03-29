#!/bin/bash
function _session() {
	[ ! -f ${session_file} ] && touch ${session_file}
	bearer=$( cat ${session_file} )
	status_code=$( curl --output /dev/null --silent --write-out "%{http_code}\n" --insecure --header "Authorization: Bearer ${bearer}" https://localhost/ovirt-engine/api )
	if [ ${status_code} -eq 401 ]; then
		session=$( curl \
			   --insecure \
			   --silent \
			   --header "Content-Type: application/x-www-form-urlencoded" \
			   --header "Accept: application/json" \
			   --data "grant_type=password&scope=ovirt-app-api&username=${user}&password=${password}" \
			   https://localhost/ovirt-engine/sso/oauth/token | sed 's/.*"access_token":"\([^"]*\)".*/\1/g' )
		echo ${session} > ${session_file}
	fi
}
function _api() {
	_session
	bearer=$( cat ${session_file} )
	curl \
	--insecure \
	--header "Accept: application/xml" \
	--header "Authorization: Bearer ${bearer}" \
	--header "Prefer: persistent-auth" \
	"${url}/${1}" 2>/dev/null > "${2}"
}

function _xpath() {
	xmllint --xpath "${1}" ${2}
}

function _psql() {
	/opt/rh/rh-postgresql10/root/usr/bin/psql -U gocloud -At -F " " -c "${1}" 
}

function _create_vm() {
	_session
	bearer=$( cat ${session_file} )
	curl \
        --silent \
	--insecure \
	--request POST \
	--header "Version: 4" \
	--header "Accept: application/xml" \
	--header "Content-Type: application/xml" \
	--header "Authorization: Bearer ${bearer}" \
	--header "Prefer: persistent-auth" \
	--data "${1}" \
	"${url}/vms"
}

function _create_image() {
	_session
        bearer=$( cat ${session_file} )
        curl \
        --silent \
        --insecure \
        --request POST \
        --header "Version: 4" \
        --header "Accept: application/xml" \
        --header "Content-Type: application/xml" \
        --header "Authorization: Bearer ${bearer}" \
        --header "Prefer: persistent-auth" \
        --data "${1}" \
        "${url}/vms/${2}/diskattachments"
}

function _get_disk() {
	_session
        bearer=$( cat ${session_file} )
        curl \
        --silent \
        --insecure \
        --header "Version: 4" \
        --header "Accept: application/xml" \
        --header "Content-Type: application/xml" \
        --header "Authorization: Bearer ${bearer}" \
        --header "Prefer: persistent-auth" \
        "${url}/disks/${1}"
}

function _create_vnic() {
	_session
        bearer=$( cat ${session_file} )
        curl \
        --silent \
        --insecure \
        --request POST \
        --header "Version: 4" \
        --header "Accept: application/xml" \
        --header "Content-Type: application/xml" \
        --header "Authorization: Bearer ${bearer}" \
        --header "Prefer: persistent-auth" \
        --data "${1}" \
        "${url}/vms/${2}/nics"
}

function _remove_vm() {
	_session
        bearer=$( cat ${session_file} )
        curl \
        --silent \
        --insecure \
        --request DELETE \
        --header "Version: 4" \
        --header "Accept: application/xml" \
        --header "Content-Type: application/xml" \
        --header "Authorization: Bearer ${bearer}" \
        --header "Prefer: persistent-auth" \
        --data " \
<action> 
  <force>true</force> 
</action>" \
        "${url}/vms/${1}"
}

function _vm_disk_xml() {
        _session
        bearer=$( cat ${session_file} )
        curl \
        --silent \
        --insecure \
        --header "Version: 4" \
        --header "Accept: application/xml" \
        --header "Content-Type: application/xml" \
        --header "Authorization: Bearer ${bearer}" \
        --header "Prefer: persistent-auth" \
        "${url}/vms/${1}/diskattachments?follow=disk"
}
