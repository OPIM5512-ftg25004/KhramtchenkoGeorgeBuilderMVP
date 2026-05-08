import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SecureVaultModule = buildModule("SecureVaultModule", (m) => {
  // Deploy the SecureVault contract
  const vault = m.contract("SecureVault");

  return { vault };
});

export default SecureVaultModule;
