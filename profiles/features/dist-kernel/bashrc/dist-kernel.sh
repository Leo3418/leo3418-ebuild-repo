if has kernel-install ${INHERITED}; then
	pkg_prerm() {
		local dir_ver="${PV}${KV_LOCALVERSION}"
		local kernel_dir="${EROOT}/usr/src/linux-${dir_ver}"
		local relfile="${kernel_dir}/include/config/kernel.release"
		# Store kernel release for use in pkg_postrm
		KV_REL="$(<"${relfile}")" || KV_REL="${dir_ver}"

		kernel-install_pkg_prerm
	}

	pkg_postrm() {
		kernel-install_pkg_postrm

		local modules_dir="${EROOT}/lib/modules/${KV_REL}"
		if [[ -d ${modules_dir} ]]; then
			local to_rm=()
			local symlink
			for symlink in "${modules_dir}/build" "${modules_dir}/source"; do
				# Clean up invalid symbolic links
				[[ -d ${symlink} ]] || to_rm+=( "${symlink}" )
			done
			if [[ ${#to_rm[@]} != 0 ]]; then
				ebegin "Cleaning up kernel modules directory"
				rm "${to_rm[@]}"
				local exit_status=$?
				eend ${exit_status}

				if [[ ${exit_status} == 0 ]]; then
					ebegin "Removing kernel modules directory"
					rmdir "${modules_dir}"
					eend $?
				fi
			fi
		fi

		local to_rm=()
		local file
		for file in \
			"${EROOT}/boot/"{config,System.map,vmlinuz}"-${KV_REL}"{,.old} \
			"${EROOT}/boot/initramfs-${KV_REL}.img"{,.old}; do
			[[ -e ${file} ]] && to_rm+=( "${file}" )
		done
		if [[ ${#to_rm[@]} != 0 ]]; then
			ebegin "Removing kernel files under /boot"
			rm "${to_rm[@]}"
			eend $?
		fi

		if [[ -z ${REPLACED_BY_VERSION} ]]; then
			ebegin "Updating bootloader configuration"
			"${EROOT}/etc/kernel/postinst.d/91-grub-mkconfig.install"
			eend $?
		fi
	}
fi
