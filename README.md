🧬 Evolutionary NFT Contract

Overview

The Evolutionary NFT Contract introduces a new kind of non-fungible token (NFT) that evolves over time.
Each NFT has a set of mutable attributes—such as color, size, speed, and strength—which can change through random evolution events or user-driven evolutions.

This design allows NFTs to grow, mutate, and diversify dynamically, blending gamification, user participation, and on-chain randomness for a living digital collectible ecosystem.

✨ Key Features

Randomized Minting:
Each NFT starts with randomized attribute values derived from the blockchain’s VRF seed for unpredictability.

Evolution Mechanism:
NFTs can evolve in two ways:

Random Evolution: Uses VRF randomness to mutate attributes unpredictably.

User-driven Evolution: Lets owners selectively boost an attribute (e.g., speed, strength, size, or color).

Cooldown Mechanism:
A cooldown of 144 blocks (~24 hours) prevents back-to-back evolutions, ensuring fair progression.

Ownership Tracking:
Each NFT is tied to its owner, with support for secure transfers between principals.

Evolution History:
Tracks how many times each user has evolved any NFT they own.

Utility Read-Only Functions:
Query NFT details such as owner, attributes, evolution availability, and time remaining until next evolution.

⚙️ Data Structures

Data Variables:

last-token-id: Tracks the latest minted token ID.

Maps:

nft-owners: Associates each token ID with its owner principal.

nft-attributes: Stores attribute values (color, size, speed, strength, generation, and last-evolution).

evolution-count: Records how many evolutions each user has initiated.

📜 Public Functions
Function	Description
(mint-nft)	Mints a new NFT with random attributes and assigns ownership to the caller.
(evolve-random token-id)	Evolves the NFT randomly, mutating its stats based on VRF randomness.
(evolve-boost token-id attribute)	Evolves the NFT based on the user’s chosen attribute (e.g., "speed").
(transfer token-id recipient)	Transfers ownership of an NFT to another principal.
🔍 Read-Only Functions
Function	Description
(get-owner token-id)	Returns the principal owner of a token.
(get-attributes token-id)	Returns current NFT attributes.
(get-last-token-id)	Retrieves the latest minted token ID.
(get-user-evolution-count user)	Shows how many evolutions the user has performed.
(can-evolve token-id)	Checks if an NFT can currently evolve.
(blocks-until-evolution token-id)	Returns the remaining blocks until the NFT can evolve again.
🔒 Private Functions

(buff-to-uint buffer): Converts a VRF seed buffer into a usable random uint.

(buff-to-uint-8 byte): Converts a single byte into an unsigned integer.

🧩 Example Workflow

Mint an NFT:

(contract-call? .evolutionary-nft mint-nft)


→ Returns a new token-id.

Check Attributes:

(contract-call? .evolutionary-nft get-attributes u1)


Evolve Randomly:

(contract-call? .evolutionary-nft evolve-random u1)


Evolve with Boost (e.g., speed):

(contract-call? .evolutionary-nft evolve-boost u1 "speed")

🧠 Design Philosophy

This contract is built to explore dynamic NFTs — tokens that change and grow with their owners’ actions or with time.
It introduces concepts suitable for on-chain games, evolving digital art, or collectible ecosystems where rarity and uniqueness increase as NFTs evolve.

✅ License

MIT License — Free for modification and distribution with attribution.