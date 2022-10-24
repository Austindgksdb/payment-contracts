# @version 0.3.7


event NewPaymentAddress:
    account: address
    payment_address: address

event PaymentReceived:
    account: address
    token: address
    amount: uint256

event NewOwnerCommitted:
    owner: address
    new_owner: address

event NewOwnerAccepted:
    old_owner: address
    owner: address


PROXY_IMPLEMENTATION: public(immutable(address))
sweeper_implementation: public(address)

owner: public(address)
future_owner: public(address)

approved_tokens: public(HashMap[address, bool])

account_to_payment_address: public(HashMap[address, address])
payment_address_to_account: public(HashMap[address, address])


@external
def __init__(_owner: address, _proxy: address):
    self.owner = _owner
    PROXY_IMPLEMENTATION = _proxy


@external
def payment_received(_token: address, _amount: uint256) -> bool:
    account: address = self.payment_address_to_account[msg.sender]
    assert account != empty(address), "Unknown caller"
    assert self.approved_tokens[_token], "Invalid payment token"

    log PaymentReceived(account, _token, _amount)
    return True


@external
def create_payment_address(_account: address = msg.sender):
    assert self.account_to_payment_address[_account] == empty(address)
    sweeper: address = create_copy_of(PROXY_IMPLEMENTATION)
    self.account_to_payment_address[_account] = sweeper
    self.payment_address_to_account[sweeper] = _account

    log NewPaymentAddress(_account, sweeper)


@external
def set_sweeper_implementation(_sweeper: address):
    assert msg.sender == self.owner

    self.sweeper_implementation = _sweeper


@external
def set_token_approvals(_tokens: DynArray[address, 100], _approved: bool):
    assert msg.sender == self.owner

    for token in _tokens:
        self.approved_tokens[token] = _approved


@external
def commit_transfer_ownership(_new_owner: address):
    """
    @notice Set a new contract owner
    """
    assert msg.sender == self.owner
    self.future_owner = _new_owner
    log NewOwnerCommitted(msg.sender, _new_owner)


@external
def accept_transfer_ownership():
    """
    @notice Accept transfer of contract ownership
    """
    assert msg.sender == self.future_owner
    log NewOwnerAccepted(self.owner, msg.sender)
    self.owner = msg.sender
