const { Aptos, AptosConfig, Ed25519PrivateKey, Network, Account, Serializer, AccountAddress, U256 } = require("@aptos-labs/ts-sdk");

const ser = new Serializer();

const amounts = [31000, 34000];

ser.serializeFixedBytes(AccountAddress.fromString("0x82e0b52f95ae57b35220726a32c3415919389aa5b8baa33a058d7125797535cc").toUint8Array());
ser.serializeFixedBytes(AccountAddress.fromString("0x12b552d6e5ae8d9eff9707f7b65423c532499ecf706bdbb9a7256a649cd86f79").toUint8Array());
ser.serializeU8(3);
ser.serializeU256(657649227699253708);
ser.serializeVector(amounts.map(amount => new U256(amount)));

// console.log("Serialized Data:", ser.toUint8Array());


// Write the serialized Uint8Array as a hex string to a text file
fs.writeFileSync('args1_output.txt', Buffer.from(ser.toUint8Array()).toString('hex'));
console.log('✅ Arguments written to args1_output.txt');