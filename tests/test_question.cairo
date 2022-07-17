%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from src.question import Question
from src.question import Test
from src.question import view_test_count
from src.question import view_test
from src.question import view_question_count
from src.question import view_questions
from src.question import create_test
from src.question import add_question
from src.question import add_questions
from src.question import add_correct_answer
from src.question import send_answer
from src.question import _get_answer_for_id
from src.question import view_question
from src.question import view_count_users_test
from src.question import view_user_test
from src.question import view_points_user_test
from starkware.starknet.common.syscalls import get_caller_address

@view
func test_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_count) = view_test_count()
    assert test_count = 0
    return ()
end

@view
func test_question_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let (question_count) = view_question_count(test_id)
    assert question_count = 0
    return ()
end

@view
func test_add_question_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let description = 'DDD'
    let optionA = 'A'
    let optionB = 'B'
    let optionC = 'C'
    let optionD = 'D'

    let (question_id) = add_question(test_id, description, optionA, optionB, optionC, optionD)
    let (question_count) = view_question_count(test_id)
    assert question_count = 1
    return ()
end

@view
func test_add_questions_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (test_id) = create_test(1)
    let (local array: Question*) = alloc() 
    assert array[0] = Question(00,11, 22, 33, 44)

    add_questions(test_id, 1, array)
    
    let (question_count) = view_question_count(test_id)
    assert question_count = 1
    return ()
end

@view
func test_add_question_correct{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    let (question: Question) = view_question(test_id, question_id)
    assert question.description = 00
    assert question.optionA = 11
    assert question.optionB = 22
    assert question.optionC = 33
    assert question.optionD = 44
    return ()
end

@view
func test_add_correct_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    
    let (test: Test) = view_test(test_id)
    assert test.open = TRUE
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    add_correct_answer(test_id, 1, array)
    
    let (test1: Test) = view_test(test_id)
    assert test1.open = FALSE

    return ()
end

@view
func test_send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (test_id) = create_test(1)
    let description = 'DDD'
    let optionA = 'A'
    let optionB = 'B'
    let optionC = 'C'
    let optionD = 'D'

    let (question_id) = add_question(test_id, description, optionA, optionB, optionC, optionD)
    let (local array : felt*) = alloc()
    assert array[0] = 1
    add_correct_answer(test_id, 1, array)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    send_answer(test_id, 1, array)

    let (points) = view_points_user_test(test_id)
    assert points = 5
    
    return ()
end

@view
func test_send_answer2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (test_id) = create_test(1)
    let (local qarray: Question*) = alloc() 
    assert qarray[0] = Question(00,11, 22, 33, 44)
    assert qarray[1] = Question(00,44, 55, 66, 77)
    assert qarray[2] = Question(00,99, 00, 11, 22)

    add_questions(test_id, 3, qarray)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    assert array[1] = 3
    assert array[2] = 2
    add_correct_answer(test_id, 3, array)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    assert array[1] = 1
    assert array[2] = 1
    send_answer(test_id, 3, array)

    let (points) = view_points_user_test(test_id)
    assert points = 5
    
    return ()
end