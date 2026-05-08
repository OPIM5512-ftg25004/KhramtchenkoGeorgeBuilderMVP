import { expect } from "chai";
import { network } from "hardhat"; // Access via network
import { parseEther } from "ethers";

describe("Reentrancy Security Research", function () {
  async function deployVaultsFixture() {
    // Connect to the EDR network and get the ethers instance
    const { ethers } = await network.getOrCreate();
    
    // In Hardhat 3, the provider is attached to the ethers object from the connection
    const provider = ethers.provider; 
    const [owner, user, attackerWallet] = await ethers.getSigners();

    const VulnerableVault = await ethers.getContractFactory("VulnerableVault");
    const vulnerableVault = await VulnerableVault.deploy();

    const SecureVault = await ethers.getContractFactory("SecureVault");
    const secureVault = await SecureVault.deploy();

    const Attacker = await ethers.getContractFactory("Attacker");

    return { vulnerableVault, secureVault, Attacker, owner, user, attackerWallet, ethers, provider };
  }

  describe("Vulnerability Analysis: VulnerableVault", function () {
    it("Should be drained by a reentrancy attack", async function () {
      const { vulnerableVault, Attacker, user, attackerWallet, provider } = await deployVaultsFixture();

      await vulnerableVault.connect(user).deposit({ value: parseEther("10") });

      const attackerContract = await Attacker.connect(attackerWallet).deploy(
        await vulnerableVault.getAddress()
      );

      // Attack triggers the recursive loop
      await attackerContract.connect(attackerWallet).initiateAttack({ value: parseEther("1") });

      // Verify the vault is empty
      const vaultBalance = await provider.getBalance(await vulnerableVault.getAddress());
      expect(vaultBalance).to.equal(0n);
      
      const attackerContractBalance = await provider.getBalance(await attackerContract.getAddress());
      expect(attackerContractBalance).to.equal(parseEther("11"));
    });
  });

  describe("Security Verification: SecureVault", function () {
    it("Should block a reentrancy attack via nonReentrant and CEI", async function () {
      const { secureVault, Attacker, user, attackerWallet, provider } = await deployVaultsFixture();

      await secureVault.connect(user).deposit({ value: parseEther("10") });

      const attackerContract = await Attacker.connect(attackerWallet).deploy(
        await secureVault.getAddress()
      );

      // The secure vault should revert the malicious transaction
      await expect(
        attackerContract.connect(attackerWallet).initiateAttack({ value: parseEther("1") })
      ).to.be.revertedWith("ReentrancyGuard: reentrant call");

      // Verify vault funds remain secure
      const vaultBalance = await provider.getBalance(await secureVault.getAddress());
      expect(vaultBalance).to.equal(parseEther("10"));
    });
  });
});
