OpenBSD AMI Builder

The `build_ami.sh` script modifies install67.img to run unattended, then builds
and installs cloud-init with all of it's dependenices. The modified image is
written to autoinstall.img.

The script then boots autoinstall.img in qemu with an EBS volume attached. qemu
will exit when the installation is complete.

Manual steps:

    1. Create an instance for building, run `pkg_add qemu`
    2. Create an empty EBS volume and attach it to the build instance
    3. Run `build_ami.sh`
    4. Create a snapshot of the EBS volume
    5. Register the snapshot as a new AMI
    6. Boot your new AMI!

TODO:

    - Automate the aforementioned manual steps
    - SSH host keys are generated twice on first boot, once by the rc scripts,
      again by cloud-init. Eliminate one of these.
    - Create a ports package for cloud-init, rather than building during install
    - Currently the AMI hangs when mounting the root filesystem on NVMe. AWS
      Nitro based instances use this (t3, c5,...).

Notes:

    - The installer configures the serial console at 115200 baud. AWS support
      for serial console varies depending on instance type.
    - The `build_ami.sh` script needs to be modified for new releases.
      Hopefully the changes are small.
    - syspatch is run during the install. It would be irresponsible to release
      unpatched AMIs when patches exist.
    - cloud-init creates an "openbsd" user with the instance's SSH key and
      passwordless sudo access to root.
    - password authentication is disabled for root.
    - We overwrite `/etc/disktab` on the build host. This is generally not a
      problem.
    - We don't resize partitions automatically. It's recommended that users
      create a new partition in the free space using disklabel after boot.

