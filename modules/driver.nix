{
  config,
  lib,
  pkgs,
  ...
}: {
  # ==========================================
  # CPU & Microcode
  # ==========================================
  # Ensures your Intel CPU gets the latest security and stability patches
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.kernelModules = ["kvm-intel"];

  # ==========================================
  # Graphics (Intel Core Ultra)
  # ==========================================
  # Loads the modern 'xe' driver early in the boot process
  boot.initrd.kernelModules = ["xe"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Necessary if you plan to game via Steam or use Wine
    extraPackages = with pkgs; [
      intel-media-driver # Hardware video acceleration (decoding/encoding)
      vpl-gpu-rt # Intel QuickSync Video
    ];
  };

  # ==========================================
  # Networking & Bluetooth
  # ==========================================
  # Based on your loaded btintel and btusb modules
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ==========================================
  # Audio (Sound Open Firmware & SoundWire)
  # ==========================================
  # Modern Intel laptops route audio through a DSP that requires closed-source firmware.
  # This ensures your ThinkPad's speakers and microphone actually work.
  hardware.firmware = with pkgs; [
    sof-firmware
  ];

  # ==========================================
  # ThinkPad Specifics & Power Management
  # ==========================================
  # Essential for updating your Lenovo BIOS and Thunderbolt firmware directly from NixOS
  services.fwupd.enable = true;

  # For modern Intel architectures (Meteor/Arrow/Lunar Lake), power-profiles-daemon
  # interacts much better with the CPU's hardware states than older tools like TLP.
  services.power-profiles-daemon.enable = true;
  boot.kernelParams = [
    "xe.force_probe=7d51"
    "i915.force_probe=!7d51"
  ];
  # Enable NVMe trim for SSD health and longevity
  services.fstrim.enable = true;
}
