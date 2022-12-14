// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import { ReentrancyGuard } from "./ReentrancyGuard.sol";

/**
 * @title CounterManager
 * @author 0age
 * @notice CounterManager contains a storage mapping and related functionality
 *         for retrieving and incrementing a per-offerer counter.
 */
contract CounterManager is ConsiderationEventsAndErrors, ReentrancyGuard {
    // Only orders signed using an offerer's current counter are fulfillable.
    mapping(address => uint256) private _counters;

    /**
     * @dev Internal function to cancel all orders from a given offerer in bulk
     *      by incrementing a counter. Note that only the offerer may increment
     *      the counter.
     *
     * @return newCounter The new counter.
     */
    function _incrementCounter() internal returns (uint256 newCounter) {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // Use the previous block hash as a quasi-random number.
        uint256 quasiRandomNumber = blockhash(block.number - 1) >> 128;

        // Utilize assembly to access counters storage mapping directly. Skip
        // overflow check as counter cannot be incremented that far.
        assembly {
            // Write the caller to scratch space.
            mstore(0, caller())

            // Write the storage slot for _counters to scratch space.
            mstore(0x20, _counters.slot)

            // Derive the storage pointer for the counter value.
            let storagePointer := keccak256(0, 0x40)

            // Derive new counter value using random number and original value.
            newCounter := add(quasiRandomNumber, sload(storagePointer))

            // Store the updated counter value.
            sstore(storagePointer, newCounter)
        }

        // Emit an event containing the new counter.
        emit CounterIncremented(newCounter, msg.sender);
    }

    /**
     * @dev Internal view function to retrieve the current counter for a given
     *      offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return currentCounter The current counter.
     */
    function _getCounter(
        address offerer
    ) internal view returns (uint256 currentCounter) {
        // Return the counter for the supplied offerer.
        currentCounter = _counters[offerer];
    }
}
