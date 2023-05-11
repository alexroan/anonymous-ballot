import { ethers } from "hardhat";
import { mimcSpongecontract } from 'circomlibjs'
import { GovernorZK, GovernorZKVotes, TimelockController } from "../typechain-types";
import { generateCommitment, calculateMerkleRootAndZKProof } from 'zk-merkle-tree';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert } from "chai";
import { time } from "@nomicfoundation/hardhat-network-helpers";

const SEED = "mimcsponge";
// the default verifier is for 20 levels, for different number of levels, you need a new verifier circuit
const TREE_LEVELS = 20;

const OPTION_A = 99;
const OPTION_B = 98;

describe("GovernorZK", () =>  {
    let signers: SignerWithAddress[]
    let voters: SignerWithAddress[]
    let governor: GovernorZK
    let governorVotes: GovernorZKVotes
    let timelockController: TimelockController

    // Register a voter and return the random commitment
    async function register(proposalId: number, signer: SignerWithAddress) {
        const commitment = await generateCommitment()
        await governor.connect(signer).registerCommitment(proposalId, commitment.commitment)
        return commitment;
    }

    // Vote for an support from a random signer, using a registered commitment
    // The commitment is used to generate the nullifier and the merkle root
    // Impossible to link the vote to the signer of the original commitment
    async function vote(randomSigner: SignerWithAddress, proposalId: number, support: number, commitment: any) {
        const cd = await calculateMerkleRootAndZKProof(governor.address, randomSigner, TREE_LEVELS, commitment, "keys/Verifier.zkey")
        await governor.connect(randomSigner).castVote(proposalId, support, cd.nullifierHash, cd.root, cd.proof_a, cd.proof_b, cd.proof_c)
    }

    before(async () => {
        signers = await ethers.getSigners()
        const MiMCSponge = new ethers.ContractFactory(mimcSpongecontract.abi, mimcSpongecontract.createCode(SEED, 220), signers[0])
        const mimcsponge = await MiMCSponge.deploy()
        const Verifier = await ethers.getContractFactory("Verifier");
        const verifier = await Verifier.deploy();
        voters = signers.slice(0, 5)
        const GovernorZKVotes = await ethers.getContractFactory("GovernorZKVotes");
        governorVotes = await GovernorZKVotes.deploy(voters.map(v => v.address));
        const TimelockController = await ethers.getContractFactory("TimelockController");
        timelockController = await TimelockController.deploy(0, [voters[0].address], [voters[0].address], voters[0].address)
        const GovernorZK = await ethers.getContractFactory("GovernorZK");
        governor = await GovernorZK.deploy(governorVotes.address, timelockController.address, TREE_LEVELS, mimcsponge.address, verifier.address);
    });

    it("Test voting one way", async () => {
        
        // let commitments = []

        // // register voters
        // for (let i = 0; i < voters.length; i++) {
        //     commitments.push(await register(voters[i]))
        // }

        // await time.increase(10);

        // // votes
        // for (let i = 0; i < voters.length; i++) {
        //     await vote(signers[i+5], OPTION_A, commitments[i])
        // }

        // assert((await governor.s_voteTally(OPTION_A)).toString() == voters.length.toString(), "OPTION_A tally not correct")
        // assert((await governor.s_voteTally(OPTION_B)).toString() == "0", "OPTION_B tally not correct")
    });
});