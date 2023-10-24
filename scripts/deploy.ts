import { ethers } from 'hardhat'
import { ParametersStruct } from '../typechain-types/contracts/WEFairFactory'

async function main() {
  // Rollux testnet Pegasys v2 router
  const routerAddress = '0x29f7Ad37EC018a9eA97D4b3fEebc573b5635fA84'

  // feeTod
  const feeTo = '0xEcAAF683E567AAD2F63Cf147dAcA75A4B9393B9C'
  const signer = '0x39AD2809F73086A63Ab2F0D8D689D1cc02579abA'
  const [owner] = await ethers.getSigners()
  console.log("owner:", await owner.address)

  const WEFairFactory = await ethers.getContractFactory('WEFairFactory')
  const wefairFactory = await WEFairFactory.deploy(feeTo, signer)
  await wefairFactory.deployed()

  console.log(`WEFairFactory deployed to ${wefairFactory.address}`)
  const dexRouterBytes = ethers.utils.id('DEX_ROUTER')
  const dexRouterSetterBytes = ethers.utils.id('DEX_ROUTER_SETTER_ROLE')
  await wefairFactory.grantRole(dexRouterSetterBytes, owner.address)
  await sleep(3000)
  await wefairFactory.grantRole(dexRouterBytes, routerAddress)
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})