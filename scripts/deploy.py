from brownie import Factory, MinimalProxy, Sweeper, accounts
from brownie_tokens import ERC20


def main():
    deployer = accounts[0]
    receiver = "0x303cCAe16140B5e784F048d1d06B0534eB789F9D"
    owner = "0x14059D8D33DBA36aa2A74ed7A52835DA04450B9d"

    factory_addr = deployer.get_deployment_address(deployer.nonce+2)
    proxy_imp = MinimalProxy.deploy(factory_addr, {'from': deployer})
    sweeper_imp = Sweeper.deploy(factory_addr, {'from': deployer})
    factory = Factory.deploy(owner, receiver, sweeper_imp, proxy_imp, {'from': deployer})


def send_token_test():
    main()

    deployer = accounts[0]
    alice = accounts[1]

    token = ERC20()
    factory = Factory[0]

    factory.set_token_approvals([token], True, {'from': factory.owner()})
    factory.create_payment_address({'from': alice})
    sweeper = Sweeper.at(factory.account_to_payment_address(alice))

    token._mint_for_testing(alice, 10**18)
    token.approve(sweeper, 2**256-1, {'from': alice})
    sweeper.send_token(token, 10**17, {'from': alice})
