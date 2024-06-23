## ERC20Swapper

This project wraps a uniswap on Polygon to call a simple swap between Matic and an arbitrary token passed as parameter.

### forge
Was used forge to setup the project structure and tests.  Follow this [link](https://book.getfoundry.sh/getting-started/installation) in order to install forge in your system

Basic steps are:
* Call
```shell
$ curl -L https://foundry.paradigm.xyz | bash
```

* Execute
```shell
$ foundryup
```

### Environment

Use ```.env.example``` as model in order to create your own ```.env``` and setup the environment variables for this project
Is expected at least this set of variables to be set

```shell
ETHERSCAN_API_KEY=""
PRIVATE_KEY="0x..."
MAINNET_RPC_URL="https://polygon..."
```
### Install dependencies
```shell
$ forge install
```

### Build
For compile and generate artifacts, use the command bellow

```shell
$ forge build
```

### Tests
Some unit tests were added to this smart contract, they can be found at `./test` folder.  The tests doesnt require a deployment coz it was crafted using a fork command from Polygon Mainnet which enable a better integration with uniswap deployed contracts
```shell
$ forge test -vvv
```
Actually the coverage for this project are 100% for lines and 100% for Functions as you can see bellow

| File                        | % Lines         | % Statements   | % Branches    | % Funcs       |
|-----------------------------|-----------------|----------------|---------------|---------------|
| src/ERC20Swapper.sol        | 100.00% (25/25) | 96.88% (31/32) | 75.00% (6/8)  | 100.00% (4/4) |



In order to run the code coverage execute this following command
```shell
$ forge coverage
```

### Deploy
Two scripts are available for this project both using UUPS pattern for upgrade, one for a deployment , and a second one to manage an upgrade in case of a new implemention is needed.

For a dry-run deployment run the command bellow
```shell
$ forge script script/ERC20Swapper.s.sol:ERC20SwapperDeployer --rpc-url <your_rpc_url> 
```

For a real deployment run this instead
```shell
$ forge script script/ERC20Swapper.s.sol:ERC20SwapperDeployer --rpc-url <your_rpc_url> --broadcast --etherscan-api-key <your_api_key> --verify
```

### Upgrade to a new version
In case of necessity of change the actual smart contract code and upgrade it, first add a new variable to your ```.env``` file.  The ```ERC20SWAPPER_PROXY``` variable can be fullfilled with the address displayed when a deployment is made in format of log of execution, something like this should be displayed

```shell
  $ deployer 0x...
  $ Implementation contract ERC20Swapper deployed at:  0x...
  $ Proxy contract ERC20Swapper deployed at:  0x...
```

After created the variable and filled with actual proxy address, execute this command bellow
```shell
$ forge script script/ERC20SwapperUP.s.sol:ERC20SwapperDeployer --rpc-url <your_rpc_url> --broadcast --etherscan-api-key <your_api_key> --verify
```

You can get a valid ```<your_rpc_url>``` from any node-as-service providers like Infura or Alchemy.  For get a valid ```<your_api_key>``` you must get a registration at PolygonScan and create a new API key there.


### Deployed addresses
 You can find a deployed version of this contract here: [Proxy](https://sepolia.etherscan.io/address/0x033757effbf66a4f9d1c876edc0513bd641cfc8a#code)

 You can find a deployed version of this contract here: [Implementation](https://sepolia.etherscan.io/address/0x564df1aa81b50ff5a38c4aa330cf218f7327cf53#code)

## Some more questions to consideer

#### Safety and trust minimization. Are user's assets kept safe during the exchange transaction? Is the exchange rate fair and correct? Does the contract have an owner?
-> As the user are triggering the ERC20Swapper contract´s function, the required fee associated with transaction cost will be directly requested for the user and all the funds passed to the function in the form of `msg.sender` are directly sended to the Uniswaps contract to perform the swap. In case of fail, all the funds sent are returned to the original caller.
The contract has an owner and its set when the contract is deployed.  Also this owner account is used to restrict to its self as the unique account able to upgrade the contract.

#### Performance. How much gas will the swapEtherToToken execution and the deployment take?
-> At this moment, the ERC20Swapper contract deployment cost is using **821513** of gas and the Proxy deployment is using **58257**.  The execution of swapEtherToToken function is using in the average an amount of **89001** of gas.  This numbers can easily be verified by running this command ```forge test --gas-report```.  An output can be seen bellow

| ERC1967Proxy.sol:ERC1967Proxy contract |                 |        |        |        |         |
|-------------------------------------------------------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                                                                           | Deployment Size |        |        |        |         |
| 58257                                                                                     | 1130            |        |        |        |         |
| Function Name                                                                             | min             | avg    | median | max    | # calls |
| initialize                                                                                | 115659          | 115659 | 115659 | 115659 | 5       |
| swapEtherToToken                                                                          | 10382           | 93900  | 98004  | 169212 | 4       |
| upgradeToAndCall                                                                          | 13353           | 13353  | 13353  | 13353  | 1       |


| src/ERC20Swapper.sol:ERC20Swapper contract |                 |        |        |        |         |
|--------------------------------------------|-----------------|--------|--------|--------|---------|
| Deployment Cost                            | Deployment Size |        |        |        |         |
| 821513                                     | 4165            |        |        |        |         |
| Function Name                              | min             | avg    | median | max    | # calls |
| initialize                                 | 115272          | 115272 | 115272 | 115272 | 5       |
| proxiableUUID                              | 321             | 321    | 321    | 321    | 1       |
| swapEtherToToken                           | 5485            | 89001  | 93101  | 164316 | 4       |
| upgradeToAndCall                           | 8454            | 8454   | 8454   | 8454   | 1       |


#### Upgradeability. How can the contract be updated if e.g. the DEX it uses has a critical vulnerability and/or the liquidity gets drained?
-> If any changes in this contrac is needed, it supports Upgradeability using the UUPS pattern.  Instructions on how to execute it can be found at the section ***Upgade to a new Version*** described in this document.

#### Usability and interoperability. Is the contract usable for EOAs? Are other contracts able to interoperate with it?
-> As no restrictions are defined at the scope, its allowed from EOAs and smart contracts to call swapEtherToToken function, but remember that only the owner can call upgrade function.
But, even not required but a important security matter was covered, the implementation of ```ReentrancyGuard``` library and the apply of ```nonReentrant``` modifier to swapEtherToToken function.

#### Readability and code quality. Are the code and design understandable and error-tolerant? Is the contract easily testable?
-> This project is following the Solidity code guide using natSpect in the head of all functions to a better readability and understanding of the code.  Also we covered the most common failure causes what makes it well error-tolerant.  You can find a easy way to test it by following the section ***Tests*** described in this document.
