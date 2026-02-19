const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const deploymentsDir = path.resolve(rootDir, 'deployments');
const artifactFile = path.resolve(
  rootDir,
  'artifacts/contracts/BNT.sol/BNT.json',
);
const backendArtifactsDir = path.resolve(
  rootDir,
  '../backend/src/wallet/artifacts',
);

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function main() {
  if (!fs.existsSync(artifactFile)) {
    throw new Error(`Missing contract artifact: ${artifactFile}`);
  }

  const artifact = readJson(artifactFile);
  const addresses = {
    bscTestnet: null,
    bscMainnet: null,
  };

  if (fs.existsSync(deploymentsDir)) {
    const deploymentFiles = fs
      .readdirSync(deploymentsDir)
      .filter((file) => file.endsWith('.bnt.json'));

    for (const file of deploymentFiles) {
      const deployment = readJson(path.join(deploymentsDir, file));
      if (deployment.network === 'bscTestnet') {
        addresses.bscTestnet = deployment.address;
      }
      if (deployment.network === 'bscMainnet') {
        addresses.bscMainnet = deployment.address;
      }
    }
  }

  fs.mkdirSync(backendArtifactsDir, { recursive: true });

  const abiOutput = path.join(backendArtifactsDir, 'bnt.abi.json');
  const addressOutput = path.join(backendArtifactsDir, 'bnt.addresses.json');

  fs.writeFileSync(abiOutput, JSON.stringify(artifact.abi, null, 2));
  fs.writeFileSync(addressOutput, JSON.stringify(addresses, null, 2));

  console.log(`[export] wrote ${abiOutput}`);
  console.log(`[export] wrote ${addressOutput}`);
}

try {
  main();
} catch (error) {
  console.error('[export] failed', error);
  process.exit(1);
}
