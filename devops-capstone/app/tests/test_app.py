import pytest

from src.app import get_dow

def test_get_dow():
    assert get_dow('2025-08-28') == 'The day of the week is Thursday'
    assert get_dow('2025-08-31') == 'The day of the week is Sunday'

def test_get_dow_invalid():
    assert get_dow('2025-08-32') == 'Invalid Date'
