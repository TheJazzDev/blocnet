const fs = require('fs');
const path = require('path');
const hre = require('hardhat');

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

async function main() {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();

  const treasury = requiredEnv('TREASURY_ADDRESS');
  const totalSupplyHuman = process.env.BNT_TOTAL_SUPPLY?.trim() || '100000000';
  const totalSupplyWei = ethers.parseUnits(totalSupplyHuman, 18);
  const ownerMultisig = process.env.OWNER_MULTISIG?.trim();

  const BNT = await ethers.getContractFactory('BNT');
  const contract = await BNT.deploy(treasury, totalSupplyWei);
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  const deployTxHash = contract.deploymentTransaction()?.hash ?? null;

  if (
    ownerMultisig &&
    ownerMultisig !== ethers.ZeroAddress &&
    ownerMultisig.toLowerCase() !== deployer.address.toLowerCase()
  ) {
    const tx = await contract.transferOwnership(ownerMultisig);
    await tx.wait();
  }

  const output = {
    network: network.name,
    chainId: Number(network.config.chainId ?? 0),
    address,
    deployTxHash,
    treasury,
    totalSupplyHuman,
    totalSupplyWei: totalSupplyWei.toString(),
    ownerMultisig: ownerMultisig || null,
    deployedAt: new Date().toISOString(),
  };

  const outDir = path.resolve(process.cwd(), 'deployments');
  fs.mkdirSync(outDir, { recursive: true });
  const outFile = path.join(outDir, `${network.name}.bnt.json`);
  fs.writeFileSync(outFile, JSON.stringify(output, null, 2));

  console.log(`[deploy] network=${network.name} address=${address}`);
  console.log(`[deploy] saved ${outFile}`);
}

main().catch((error) => {
  console.error('[deploy] failed', error);
  process.exit(1);
});
