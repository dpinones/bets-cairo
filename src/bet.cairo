%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

struct Bet:
    member teamA: felt
    member teamB: felt
end

@storage_var
func match_count() -> (count: felt):
end

@storage_var
func bet_count(id_match: felt) -> (bet_count: felt):
end

@storage_var
func bets(id_match: felt, id_bet: felt) -> (bet: Bet):
end

@view
func view_match_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (count: felt):
    let (count) = match_count.read() 
    return (count)
end

@view
func view_bet_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id_match: felt) -> (bet_count: felt):
    let (count) = bet_count.read(id_match)
    return (count)
end

@view
func view_bets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id_match: felt) -> (records_len: felt, records: Bet*):
    alloc_locals

    let (records: Bet*) = alloc()
    let (count_bets) = bet_count.read(id_match)
    _recurse_view_solution_records(id_match, count_bets, records, 0)

    return (count_bets, records)
end

func _recurse_view_solution_records {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id_match: felt,
        len : felt,
        arr : Bet*,
        idx : felt
    ) -> ():
    
    if idx == len:
        return ()
    end
    
    let (record : Bet) = bets.read(id_match, idx)
    assert arr[idx] = record
    
    _recurse_view_solution_records (id_match, len, arr, idx+1)
    return()
end

@external
func create_match{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (id_match: felt):
    let (id_match) = match_count.read()
    match_count.write(id_match + 1)
    return (id_match)
end

@external
func add_bet {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_match: felt, teamA: felt, teamB: felt) -> (
    id_bet: felt):

    let (bet) = bet_count.read(id_match)
    bets.write(id_match, bet, Bet(teamA, teamB))
    bet_count.write(id_match, bet + 1)
    
    return (bet)
end

@external
func is_winner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_match: felt) -> (
    winners: felt):

    let (bet) = bet_count.read(id_match)
    let (winners) = matching(id_match, 0, bet)

    return (winners)
end

func matching{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id_match: felt, id_bet:felt, len: felt) -> (total: felt):
    alloc_locals
    if len == 0:
        return (0)
    end

    let (bet: Bet) = bets.read(id_match, id_bet)
    local t
    if bet.teamA == 2:
        if bet.teamB == 2:
            t = 1
        else:
            t = 0
        end
    else:
        t = 0
    end
    let (local total) = matching(id_match, id_bet + 1, len - 1)  
    let res = t + total
    return (res)
end