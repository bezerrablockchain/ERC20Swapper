## ERC20Swapper
This project was crafted to work with UniswapV3 on Polygon POS at mainnet, to execute a simple swap between an arbitrary token and Wrapped Matic.

When setting the ```MAINNET_RPC_URL``` please use a valid endpoint RPC to the Polygon POS Mainnet.  And dont worry, when running the tests, no fee will be charged, it means, for running the tests you dont even need an account set, this is possible because the test suite forks the mainnet and impersonate account.

However you need to set ```PRIVATE_KEY``` at your env file with some balance on it, *if you want to run the deployment script.*

About ```.env``` file configuration, see the section ```Environment``` bellow in this document.

This project wraps a uniswapV3 on Polygon POS mainnet to call a simple swap between Matic and an arbitrary token passed as parameter.  

Please refer to the last section of this document has some consideration about topics like: ***Safety, Performance, Upgradeability, and Code quality***.

### Set of contracts and its description
#### src/contracts
* **IERC20Swapper.sol**: Main contract minimal interface
* **ERC20Swapper.sol**: Main contract to call swaps execution
* **ERC20SwapperV2.sol**: Second version available in order to execute an upgrade if desired
* **UniswapPolygon.sol**: Uniswaps connection and logic to perform the swap call

#### src/test
* **ERC20SwapperTester.t.sol**: Test file.  Tests all the functions and the Upgradeability feature

#### src/script
* **ERC20Swapper.s.sol**: First contract deployment using foundry and UUP pattern
* **ERC20SwapperUp.s.sol**: Use this in case of needed upgrade

### Installation of Foundry (forge)
It was used Foundry to setup the project structure and tests.  Follow this [link](https://book.getfoundry.sh/getting-started/installation) in order to install forge in your system

Basic steps are:
* Call
```shell
$ curl -L https://foundry.paradigm.xyz | bash
```

* Execute
```shell
$ foundryup
```

### Clone the project
This project can be found [here](https://github.com/bezerrablockchain/ERC20Swapper).  Clone it into your system, enter into the root folder ```ERC20Swapper``` and follow the instructions bellow in order to correct execute it.

### Environment

Use ```.env.example``` as model in order to create your own ```.env``` and setup the environment variables for this project
Is expected at least this set of variables to be set

```shell
ERC20SWAPPER_PROXY="0xA770d67145F627088ec2D120F0e447c7d756cdD1"
OWNER="0xEdA4e72077E8df4fD8e2267add8c0cfF68382Dd5"

PRIVATE_KEY="0x..."
MAINNET_RPC_URL="https://polygon-mainnet..."
ETHERSCAN_API_KEY=""
```
* ERC20SWAPPER_PROXY: This is the current deployed proxy address, leave as it is, or change in case of a new deployment
* OWNER: The account used to do the deployment, it is important to test the upgradeability feature
* PRIVATE_KEY: A valid privatekey, "0x...", this account will be used for deploy and/or update the contracts, for the tests execution its not necessary, as the tests impersonates the necessary accounts
* MAINNET_RPC_URL: A valid rpc from any node-as-a-service provider, like infura or alchemy.  For running the tests, please use a Polygon POS mainnet one
* ETHERSCAN_API_KEY: This is necessary for verify the smart contract code at PolygonScan explorer, go to **PolygonScan** and get an API-KEY

### Install dependencies
This project uses Openzeppelin libraries, the installation is mandatory to run the project locally, use the command bellow to to it
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
| src/ERC20Swapper.sol        | 100.00% (14/14) | 93.75% (15/16) | 83.33% (5/6)  | 100.00% (4/4) |



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
 You can find a deployed version of this contract here: [Proxy](https://polygonscan.com/address/0xa770d67145f627088ec2d120f0e447c7d756cdd1#code)

 You can find a deployed version of this contract here: [Implementation](https://polygonscan.com/address/0xa1d2e318f2ab7b18f9993d67c436ad32bfc039ff#code)

## Some more questions to consideer

#### Safety and trust minimization. Are user's assets kept safe during the exchange transaction? Is the exchange rate fair and correct? Does the contract have an owner?
-> As the user are triggering the ERC20Swapper contract´s function, the required fee associated with transaction cost will be directly requested for the user and all the funds passed to the function in the form of `msg.sender` are directly sended to the Uniswaps contract to perform the swap. In case of fail, all the funds sent are returned to the original caller.
The contract has an owner and its set when the contract is deployed.  Also this owner account is used to restrict to its self as the unique account able to upgrade the contract.

#### Performance. How much gas will the swapEtherToToken execution and the deployment take?
-> At this moment, the ERC20Swapper contract deployment cost is using **835926** of gas and the Proxy deployment is using **58257**.  The execution of swapEtherToToken function is using in the average an amount of **86038** of gas.  This numbers can easily be verified by running this command ```forge test --gas-report```.  An output can be seen bellow

| ERC1967Proxy contract |                 |       |        |        |         |
|-----------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost       | Deployment Size |       |        |        |         |
| 58257                 | 1130            |       |        |        |         |
| Function Name         | min             | avg   | median | max    | # calls |
| getVersion            | 906             | 3156  | 3156   | 5406   | 2       |
| initialize            | 71511           | 71511 | 71511  | 71511  | 5       |
| swapEtherToToken      | 10315           | 90938 | 94428  | 164581 | 4       |
| upgradeToAndCall      | 8952            | 8952  | 8952   | 8952   | 1       |


| ERC20Swapper contract |                 |       |        |        |         |
|-----------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost       | Deployment Size |       |        |        |         |
| 835926                | 4237            |       |        |        |         |
| Function Name         | min             | avg   | median | max    | # calls |
| getVersion            | 510             | 510   | 510    | 510    | 1       |
| initialize            | 71124           | 71124 | 71124  | 71124  | 5       |
| swapEtherToToken      | 5418            | 86038 | 89525  | 159685 | 4       |
| upgradeToAndCall      | 8553            | 8553  | 8553   | 8553   | 1       |

#### Upgradeability. How can the contract be updated if e.g. the DEX it uses has a critical vulnerability and/or the liquidity gets drained?
-> If any changes in this contrac is needed, it supports Upgradeability using the UUPS pattern.  Instructions on how to execute it can be found at the section ***Upgade to a new Version*** described in this document.

#### Usability and interoperability. Is the contract usable for EOAs? Are other contracts able to interoperate with it?
-> As no restrictions are defined at the scope, its allowed from EOAs and smart contracts to call swapEtherToToken function, but remember that only the owner can call upgrade function.
But, even not required but a important security matter was covered, the implementation of ```ReentrancyGuard``` library and the apply of ```nonReentrant``` modifier to swapEtherToToken function.

#### Readability and code quality. Are the code and design understandable and error-tolerant? Is the contract easily testable?
-> This project is following the Solidity code guide using natSpect in the head of all functions to a better readability and understanding of the code.  Also we covered the most common failure causes what makes it well error-tolerant.  You can find a easy way to test it by following the section ***Tests*** described in this document.
