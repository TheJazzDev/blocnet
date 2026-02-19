const fs = require('fs');
const path = require('path');
const hre = require('hardhat');

function readDeployment(networkName) {
  const file = path.resolve(process.cwd(), 'deployments', `${networkName}.bnt.json`);
  if (!fs.existsSync(file)) {
    throw new Error(`Missing deployment file: ${file}`);
  }

  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

async function main() {
  const { network } = hre;
  const deployment = readDeployment(network.name);

  try {
    await hre.run('verify:verify', {
      address: deployment.address,
      constructorArguments: [deployment.treasury, deployment.totalSupplyWei],
      contract: 'contracts/BNT.sol:BNT',
    });
    console.log(`[verify] success ${deployment.address}`);
  } catch (error) {
    const message = String(error);
    if (message.toLowerCase().includes('already verified')) {
      console.log(`[verify] already verified ${deployment.address}`);
      return;
    }
    throw error;
  }
}

main().catch((error) => {
  console.error('[verify] failed', error);
  process.exit(1);
});
