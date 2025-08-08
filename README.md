//owner by object
lock_anmis: 0xb59d0b4df1e4a5002f7c103713704da3a15e9dc2b1d9a63c5fd97f74636684df

// owner by EOA 
0xf0359b44b653a34f4b1a80242e95eb116410fa93284bc8139dae6a83a8bf2bb6 

aptos move create-object-and-publish-package --address-name aptos_tutorial 

aptos move upgrade-object-package --object-address 0xf0359b44b653a34f4b1a80242e95eb116410fa93284bc8139dae6a83a8bf2bb6


Do you want to upgrade the package 'aptos' at object address 0xf0359b44b653a34f4b1a80242e95eb116410fa93284bc8139dae6a83a8bf2bb6 [yes/no] >
yes
package size 8004 bytes
Do you want to submit a transaction for a range of [12900 - 19300] Octas at a gas unit price of 100 Octas? [yes/no] >
yes
Transaction submitted: https://explorer.aptoslabs.com/txn/0x864c875c3afe66801d92c90ac9a3948343d37eba85fcf8ccb98bdb4e2f053a93?network=mainnet
Code was successfully upgraded at object address 0xf0359b44b653a34f4b1a80242e95eb116410fa93284bc8139dae6a83a8bf2bb6

Generate payload: 
aptos move build-publish-payload --json-output-file payload.json

