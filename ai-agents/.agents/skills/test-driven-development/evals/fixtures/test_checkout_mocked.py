"""Existing test file for the mocking eval case."""

from unittest.mock import MagicMock

from shop.checkout import checkout
from shop.cart import Cart


def test_checkout_calls_payment_service() -> None:
    cart = Cart()
    cart.add(product_id="sku-1", price=100)
    payment_service = MagicMock()
    inventory = MagicMock()
    pricing = MagicMock()
    pricing.total.return_value = 100

    checkout(cart, payment_service, inventory, pricing)

    payment_service.process.assert_called_once_with(100)
    inventory.reserve.assert_called_once()
    assert pricing.total.call_count == 1
