%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from src.forms import Question
from src.forms import QuestionDto
from src.forms import Test
from src.forms import view_test_count
from src.forms import view_test
from src.forms import view_question_count
from src.forms import view_questions
from src.forms import create_test
from src.forms import add_questions
from src.forms import send_answer
from src.forms import _get_answer_for_id
from src.forms import view_question
from src.forms import view_question_owner
from src.forms import view_count_users_test
from src.forms import view_user_test
from src.forms import view_points_user_test
from src.forms import ready_test
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
func test_add_questions_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (test_id) = create_test(1)
    let (local array: Question*) = alloc() 
    assert array[0] = Question(00,11, 22, 33, 44, 1)

    add_questions(test_id, 1, array)
    
    let (question_count) = view_question_count(test_id)
    assert question_count = 1
    return ()
end

@view
func test_add_question_correct{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (test_id) = create_test(1)

    let (local qarray: Question*) = alloc() 
    assert qarray[0] = Question(00,11, 22, 33, 44, 1)
    add_questions(test_id, 1, qarray)

    let (question: Question) = view_question_owner(test_id, 0)
    assert question.description = 00
    assert question.optionA = 11
    assert question.optionB = 22
    assert question.optionC = 33
    assert question.optionD = 44
    assert question.optionCorrect = 1
    return ()
end

@view
func test_add_correct_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    
    let (test_id) = create_test(1)

    let (test: Test) = view_test(test_id)
    assert test.open = TRUE

    let (local qarray: Question*) = alloc() 
    assert qarray[0] = Question(00,11, 22, 33, 44, 1)
    add_questions(test_id, 1, qarray)
    

    ready_test(test_id)

    let (test1: Test) = view_test(test_id)
    assert test1.open = FALSE

    return ()
end

@view
func test_send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (test_id) = create_test(1)
    let (local qarray: Question*) = alloc() 
    assert qarray[0] = Question(00,11, 22, 33, 44, 1)
    add_questions(test_id, 1, qarray)

    ready_test(test_id)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    send_answer(test_id, 1, array)

    let (caller_address) = get_caller_address()
    let (points) = view_points_user_test(caller_address, test_id)
    assert points = 5
    
    return ()
end

@view
func test_send_answer2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (test_id) = create_test(1)
    let (local qarray: Question*) = alloc() 
    assert qarray[0] = Question(00,11, 22, 33, 44, 1)
    assert qarray[1] = Question(00,44, 55, 66, 77, 3)
    assert qarray[2] = Question(00,99, 00, 11, 22, 2)

    add_questions(test_id, 3, qarray)
    
    ready_test(test_id)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    assert array[1] = 1
    assert array[2] = 1
    send_answer(test_id, 3, array)

    let (caller_address) = get_caller_address()
    let (points) = view_points_user_test(caller_address, test_id)
    assert points = 5
    
    return ()
end