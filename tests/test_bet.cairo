%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.bet import Bet

from src.bet import match_count
from src.bet import bet_count
from src.bet import bets
from src.bet import create_match
from src.bet import is_winner

from src.bet import add_bet

@external
func test_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (id_match) = create_match()

    let (id_bet) = add_bet(id_match, 2, 2)
    let (id_bet1) = add_bet(id_match, 0, 0)
    let (id_bet2) = add_bet(id_match, 2, 2)

    let (count1) = bet_count.read(0)
    assert count1 = 3

    let (bet2: Bet) = bets.read(id_match, id_bet2)
    assert bet2.teamA = 2

    let (win) = is_winner(id_match)
    assert win = 2

    return ()
end