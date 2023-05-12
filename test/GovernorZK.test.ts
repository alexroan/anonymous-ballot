import { ethers } from "hardhat";
import { mimcSpongecontract } from 'circomlibjs'
import { GovernorZK, GovernorZKVotes, TimelockController } from "../typechain-types";
import { generateCommitment, calculateMerkleRootAndZKProof } from 'zk-merkle-tree';
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert } from "chai";
import { mine } from "@nomicfoundation/hardhat-network-helpers";

const SEED = "mimcsponge";
// the default verifier is for 20 levels, for different number of levels, you need a new verifier circuit
const TREE_LEVELS = 20;

const AGAINST = 0;
const FOR = 1;
const ABSTAIN = 2;

describe("GovernorZK", () =>  {
    let signers: SignerWithAddress[]
    let voters: SignerWithAddress[]
    let governor: GovernorZK
    let governorVotes: GovernorZKVotes
    let timelockController: TimelockController

    // Register a voter and return the random commitment
    async function register(proposalId: number, signer: SignerWithAddress) {
        const commitment = await generateCommitment()
        const tx = await governor.connect(signer).registerCommitment(proposalId, commitment.commitment)
        const receipt = await tx.wait()
        console.log("registerCommitment gasUsed", receipt.gasUsed.toString())
        return commitment;
    }

    // Vote for an support from a random signer, using a registered commitment
    // The commitment is used to generate the nullifier and the merkle root
    // Impossible to link the vote to the signer of the original commitment
    async function vote(randomSigner: SignerWithAddress, proposalId: number, support: number, commitment: any) {
        const cd = await calculateMerkleRootAndZKProof(governor.address, randomSigner, TREE_LEVELS, commitment, "keys/Verifier.zkey")
        const tx = await governor.connect(randomSigner)['castVote(uint256,uint8,uint256,uint256,uint256[2],uint256[2][2],uint256[2])'](proposalId, support, cd.nullifierHash, cd.root, cd.proof_a, cd.proof_b, cd.proof_c)
        const receipt = await tx.wait()
        console.log("castVote gasUsed", receipt.gasUsed.toString())
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

    it("Test 5 participants voting FOR a proposal", async () => {        
        const tx = await governor['propose(address[],uint256[],bytes[],string)']([voters[0].address], [100], [0x00], "Test")
        const receipt = await tx.wait()
        const proposalId = receipt.events[0].args.proposalId.toString();

        let commitments = []

        // register voters
        for (let i = 0; i < voters.length; i++) {
            commitments.push(await register(proposalId, voters[i]))
        }

        await mine(46027)

        // votes
        for (let i = 0; i < voters.length; i++) {
            await vote(signers[i+5], proposalId, FOR, commitments[i])
        }

        await mine(46027)

        // Assert that it succeeds
        assert(await governor.state(proposalId) == 4)
    });
});