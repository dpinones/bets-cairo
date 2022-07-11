%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

struct Question:
    member description: felt
    member possible_answer1: felt
    member possible_answer2: felt
    member possible_answer3: felt
    member possible_answer4: felt
    # member correct_answer: felt
end

@storage_var
func test_count() -> (count: felt):
end

@storage_var
func question_count(id_test: felt) -> (question_count: felt):
end

@storage_var
func questions(id_test: felt, id_question: felt) -> (question: Question):
end

@storage_var
func answers_correct(id_test: felt, id_question: felt) -> (answers_correct: felt):
end

@view
func view_test_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (count: felt):
    let (count) = test_count.read() 
    return (count)
end

@view
func view_question_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id_test: felt) -> (bet_count: felt):
    let (count) = question_count.read(id_test)
    return (count)
end

@view
func view_cuestions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id_test: felt) -> (records_len: felt, records: Question*):
    alloc_locals

    let (records: Question*) = alloc()
    let (count_question) = question_count.read(id_test)
    _recurse_view_solution_records(id_test, count_question, records, 0)

    return (count_question, records)
end

func _recurse_view_solution_records {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id_test: felt,
        len : felt,
        arr : Question*,
        idx : felt
    ) -> ():
    
    if idx == len:
        return ()
    end
    
    let (record : Question) = questions.read(id_test, idx)
    assert arr[idx] = record
    
    _recurse_view_solution_records (id_test, len, arr, idx+1)
    return()
end

@external
func create_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (id_match: felt):
    let (id_test) = test_count.read()
    test_count.write(id_test + 1)
    return (id_test)
end

@external
func add_question {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test: felt,
    description: felt,
    possible_answer1: felt,
    possible_answer2: felt,
    possible_answer3: felt,
    possible_answer4: felt
    ) -> (
    id_question: felt):

    let (id_question) = question_count.read(id_test)
    questions.write(id_test, id_question, Question(
        description,
        possible_answer1,
        possible_answer2,
        possible_answer3,
        possible_answer4
    ))
    question_count.write(id_test, id_question + 1)
    
    return (id_question)
end

@external
func add_correct_answer {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test: felt,
    answers_len: felt,
    answers: felt*
    ) -> ():
    let (count_question) = question_count.read(id_test)
    _recurse_add_correct_answer(id_test, count_question, answers, 0)

    return()
end

func _recurse_add_correct_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id_test: felt,
        len : felt,
        arr : felt*,
        idx : felt
    ) -> ():
    
    if idx == len:
        return ()
    end
    
    answers_correct.write(id_test, idx, arr[idx])
    
    _recurse_add_correct_answer (id_test, len, arr, idx+1)
    return()
end

@view
func points {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test: felt,
    answers_len: felt,
    answers: felt*
    ) -> ():
    let (count_question) = question_count.read(id_test)
    _recurse_add_answers(id_test, count_question, answers, 0)

    return()
end

func _recurse_add_answers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id_test: felt,
        len : felt,
        arr : felt*,
        idx : felt
    ) -> (points: felt):
    alloc_locals    
    if idx == len:
        return (0)
    end
    
    let (answer_correct) = answers_correct.read(id_test, idx)
    local t
    if answer_correct == arr[idx]:
        t = 5
    else:
        t = 0
    end

    let (local total) = _recurse_add_answers (id_test, len-1, arr, idx+1)    
    let res = t + total
    return(total)
end