// const { Aptos, AptosConfig, Ed25519PrivateKey, Network, Account } = require("@aptos-labs/ts-sdk");
// const fs = require('fs');
// const yaml = require('js-yaml');

// const updatePackage = async (path) => {
//     const jsonSync = fs.readFileSync(`payload.json`, 'utf8');
//     const payload = JSON.parse(jsonSync);

//     const arg1 = new Uint8Array(Buffer.from(payload.args[0].value.replace('0x', ''), 'hex'));
//     const arg2 = payload.args[1].value.map(hex =>
//         new Uint8Array(Buffer.from(hex.replace('0x', ''), 'hex'))
//     );

//     // Convert Uint8Array to normal arrays for JSON serialization
//     const output = {
//         arg1: Array.from(arg1),
//         arg2: arg2.map(arr => Array.from(arr))
//     };

//     fs.writeFileSync('args_output.json', JSON.stringify(output, null, 2), 'utf8');
//     console.log('✅ Arguments written to args_output.json');
// };

// updatePackage().then();

const { Aptos, AptosConfig, Ed25519PrivateKey, Network, Account } = require("@aptos-labs/ts-sdk");
const fs = require('fs');
const yaml = require('js-yaml');
const { load } = require('js-toml');
const readline = require('readline');

const config = new AptosConfig({ network: Network.MAINNET });
const aptos = new Aptos(config);

const moduleconfig = yaml.load(fs.readFileSync('.aptos/config.yaml', 'utf8'));
const privateKey = moduleconfig.profiles.default.private_key;
const EprivateKey = new Ed25519PrivateKey(privateKey);
const account = Account.fromPrivateKey({ privateKey: EprivateKey });
// const Moveconfig = load(fs.readFileSync('swap/Move.toml', 'utf8'));
// const EBISUS_BAY_ADDRESS = Moveconfig.addresses.ebisus_bay;
const EBISUS_BAY_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000001;

console.log("account-address", account.accountAddress.toString());
/// aptos move build-publish-payload --skip-fetch-latest-git-deps --json-output-file bank.json

const updatePackage = async (path) => {
  const jsonSync = fs.readFileSync(`payload.json`, 'utf8');
  const payload = JSON.parse(jsonSync);

  const tx = await aptos.transaction.build.simple({
    sender: account.accountAddress,
    data: {
      function: "0x1::object_code_deployment::upgrade",
      typeArguments: [],
      functionArguments: [
        new Uint8Array(Buffer.from(payload.args[0].value.replace('0x', ''), 'hex')),
        payload.args[1].value.map(hex =>
          new Uint8Array(Buffer.from(hex.replace('0x', ''), 'hex'))
        ), 
        "0xf0359b44b653a34f4b1a80242e95eb116410fa93284bc8139dae6a83a8bf2bb6"
      ]
    }
  });

  console.log("\n=== update transaction ===\n");
  const committedTxn = await aptos.signAndSubmitTransaction({
    signer: account,
    transaction: tx
  });

  await aptos.waitForTransaction({ transactionHash: committedTxn.hash });
  console.log(`✅ Committed transaction: ${committedTxn.hash}`);
};

updatePackage().then()

// // CLI prompt input path
// const rl = readline.createInterface({
//   input: process.stdin,
//   output: process.stdout
// });

// rl.question("📁 Enter the package folder path (e.g., swap): ", async (inputPath) => {
//   try {
//     await updatePackage(inputPath.trim());
//   } catch (err) {
//     console.error("❌ Error:", err.message);
//   } finally {
//     rl.close();
//   }
// });