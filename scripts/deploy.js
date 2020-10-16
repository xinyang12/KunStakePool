const { ethers, upgrades } = require("@nomiclabs/buidler");

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      await deployer.getAddress()
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const KunStakePool = await ethers.getContractFactory("KunStakePool");
    const kunStakePool = await KunStakePool.deploy();
  
    await kunStakePool.deployed();
  
    console.log("KunStakePool address:", kunStakePool.address);
    // const KunStakePool = await ethers.getContractFactory("KunStakePool");
    // console.log("Deploying KunStakePool...");
    // const pool = await upgrades.deployProxy(KunStakePool, ['0x51BFe942a15219c8968060CF532B89D03eaBd007', '0x51BFe942a15219c8968060CF532B89D03eaBd007', Number(1604160000)], { initializer: 'initialize', unsafeAllowCustomTypes: true });
    // console.log("KunStakePool deployed to:", pool.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });