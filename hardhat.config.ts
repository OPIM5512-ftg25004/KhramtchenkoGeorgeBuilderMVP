import { configVariable, defineConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-keystore";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-ethers"; 
import "@nomicfoundation/hardhat-ignition-ethers"; 
import "@nomicfoundation/hardhat-ethers-chai-matchers";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
// 1. Import the specific Mocha plugin
import hardhatMocha from "@nomicfoundation/hardhat-mocha";
import hardhatEthers from "@nomicfoundation/hardhat-ethers"; // Add this import
import hardhatChaiMatchers from "@nomicfoundation/hardhat-ethers-chai-matchers";
import hardhatIgnition from "@nomicfoundation/hardhat-ignition-ethers";
import * as dotenv from "dotenv";

dotenv.config();

export default defineConfig({
  // 2. Register it here so Hardhat knows to run it
  plugins: [
    hardhatVerify,
    hardhatIgnition,
    hardhatMocha,
    hardhatEthers,
    hardhatChaiMatchers
  ],
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.SEPOLIA_PRIVATE_KEY ? [process.env.SEPOLIA_PRIVATE_KEY] : [],
    },
  },
});
