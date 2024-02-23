import "@nomicfoundation/hardhat-toolbox";
import "@zetachain/toolkit/tasks";
import "./tasks/deploy";
import "./tasks/create";
import "./tasks/update";
import "./tasks/mint";
import "./tasks/add-wl";

import { getHardhatConfigNetworks } from "@zetachain/networks";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      ],
    },

    ...getHardhatConfigNetworks(),
  },
  solidity: "0.8.7",
};

export default config;
