%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_nn,
    assert_le,
    assert_lt,
    assert_in_range,
)

#
# Events
#

@event
func TestCreated(id_test: felt):
end

@event
func SendPoint(id_test : felt, point: felt):
end

#
# Struct
#

struct Test:
    member name : felt
    member created_at : felt
end

struct Question:
    member description : felt
    member optionA : felt
    member optionB : felt
    member optionC : felt
    member optionD : felt
    member optionCorrect : felt
end

struct QuestionDto:
    member description : felt
    member optionA : felt
    member optionB : felt
    member optionC : felt
    member optionD : felt
end

#
# Storage
#

### TEST ###

#lista de test
@storage_var
func tests(id_test : felt) -> (test : Test):
end

#cantidad de test
@storage_var
func tests_count() -> (count : felt):
end

### QUESTION ###

#lista de preguntas
@storage_var
func questions(id_test : felt, id_question : felt) -> (question : Question):
end

#cantidad de preguntas por test
@storage_var
func questions_count(id_test : felt) -> (questions_count : felt):
end

#respuestas correctas por test / de uso interno
@storage_var
func correct_test_answers(id_test : felt, id_question : felt) -> (correct_test_answer: felt):
end

### USERS ###

# respuesta nro por test / forma de obtener la lista de usuarios por test
@storage_var
func users_test(id_test : felt, id_answer : felt) -> (user : felt):
end

#cantidad de usuarios por test
@storage_var
func count_users_test(id_test : felt) -> (count_users : felt):
end

#usuarios que hicieron el test / boolean
@storage_var
func check_users_test(user_address : felt, id_test : felt) -> (bool : felt):
end

#puntos de un usuario por test
@storage_var
func points_users_test(user_address : felt, id_test : felt) -> (points : felt):
end

#respuestas de un usuario por test
@storage_var
func answer_users_test(user_address : felt, id_test : felt, id_question : felt) -> (
    answer : felt
):
end

#
# Modifier
#

#
# Getters
#

@view
func view_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt
) -> (test : Test):
    let (res : Test) = tests.read(id_test)
    return (res)
end

@view
func view_test_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : felt
):
    let (count) = tests_count.read()
    return (count)
end

@view
func view_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt
) -> (records_len : felt, records : QuestionDto*):
    alloc_locals

    let (records : QuestionDto*) = alloc()
    let (count_question) = questions_count.read(id_test)
    _recurse_view_solution_records(id_test, count_question, records, 0)

    return (count_question, records)
end

@view
func view_question_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt
) -> (question_count : felt):
    let (count) = questions_count.read(id_test)
    return (count)
end

@view
func view_users_test_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt
) -> (count_user : felt):

    let (count) = count_users_test.read(id_test)
    return (count)
end

@view
func view_score_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt
) -> (records_len : felt, records : (felt, felt)*):
    alloc_locals

    let (records : (felt, felt)*) = alloc()
    let (count) = count_users_test.read(id_test)
    _recurse_view_answers_records(id_test, count, records, 0)

    return (count, records)
end

#
# Externals
#

@external
func create_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt,
    dquestions_len : felt,
    dquestions : Question*
) -> ():
    #create test
    alloc_locals
    let (local id_test) = _create_test(name)

    #add questions
    _add_questions(id_test, dquestions_len, dquestions)
    TestCreated.emit(id_test)
    return ()
end

@external
func send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt, answers_len : felt, answers : felt*
) -> ():
    alloc_locals

    let (count) = tests_count.read()
    with_attr error_message("Test not found"):
        assert_in_range(id_test + 1 , 0, count +1)
    end

    let (count_question) = questions_count.read(id_test)
    with_attr error_message("Length of answers must be equal to the number of questions"):
        assert answers_len = count_question
    end

    let (caller_address) = get_caller_address()
    let (bool) = check_users_test.read(caller_address, id_test)
    with_attr error_message("You have already answered this test"):
        assert bool = FALSE
    end
    
    let (point) = _recurse_add_answers(id_test, count_question, answers, 0)

    points_users_test.write(caller_address, id_test, point)
    check_users_test.write(caller_address, id_test, TRUE)
    
    let (count_users) = count_users_test.read(id_test)
    users_test.write(id_test, count_users, caller_address)
    count_users_test.write(id_test, count_users + 1)

    SendPoint.emit(id_test, point) 
    return ()
end

#
# Internal
#

func _create_test{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name : felt
) -> (id_test : felt):

    let (id_test) = tests_count.read()
    let (caller_address) = get_caller_address()
    tests.write(id_test, Test(name, caller_address))
    tests_count.write(id_test + 1)
    return (id_test)
end

func _add_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt,
    dquestions_len: felt,
    dquestions : Question*
) -> ():
    alloc_locals
    #len > 0
    assert_le(0, dquestions_len)

    let (count_question) = questions_count.read(id_test)
    _add_a_questions(id_test, count_question, dquestions_len, dquestions)

    questions_count.write(id_test, count_question + dquestions_len)

    return ()
end

func _recurse_view_solution_records{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(id_test : felt, len : felt, arr : QuestionDto*, idx : felt) -> ():
    if idx == len:
        return ()
    end

    let (record : Question) = questions.read(id_test, idx)
    assert arr[idx] = QuestionDto(record.description, record.optionA, record.optionB, record.optionC, record.optionD)

    _recurse_view_solution_records(id_test, len, arr, idx + 1)
    return ()
end


func _recurse_view_answers_records{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(id_test : felt, len : felt, arr : (felt, felt)*, idx : felt) -> ():
    if idx == len:
        return ()
    end

    let (user: felt) = users_test.read(id_test, idx)
    let (point) = points_users_test.read(user, id_test)
    assert arr[idx] = (user, point)

    _recurse_view_answers_records(id_test, len, arr, idx + 1)
    return ()
end

func _recurse_add_answers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt, len : felt, arr : felt*, idx : felt
) -> (points : felt):
    alloc_locals
    if len == 0:
        return (0)
    end

    let (answer_correct) = correct_test_answers.read(id_test, idx)

    tempvar answer_user : felt
    answer_user = cast([arr], felt)
    # 0 >= answer <= 3
    assert_in_range(answer_user, 0, 4)
    let (caller_address) = get_caller_address()
    answer_users_test.write(caller_address, id_test, idx, answer_user)

    local t
    if answer_user == answer_correct:
        t = 5
    else:
        t = 0
    end
    let (local total) = _recurse_add_answers(id_test, len - 1, arr + 1, idx + 1)
    let res = t + total
    return (res)
end

func _get_answer_for_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    question : Question, id_answer : felt
) -> (correct_answer : felt):
    tempvar answer_user : felt
    if id_answer == 0:
        answer_user = question.optionA
    end
    if id_answer == 1:
        answer_user = question.optionB
    end
    if id_answer == 2:
        answer_user = question.optionC
    end
    if id_answer == 3:
        answer_user = question.optionD
    end
    return (answer_user)
end

func _add_a_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_test : felt,
    id_question : felt,
    dquestions_len: felt,
    dquestions : Question*
) -> ():
    if dquestions_len == 0:
        return ()
    end

    let description = [dquestions].description
    let optionA = [dquestions].optionA
    let optionB = [dquestions].optionB
    let optionC = [dquestions].optionC
    let optionD = [dquestions].optionD
    let optionCorrect = [dquestions].optionCorrect
    
    with_attr error_message("Option correct must be between 0 and 3"):
        assert_in_range(optionCorrect, 0, 4)
    end

    correct_test_answers.write(id_test, id_question, optionCorrect)

    questions.write(
        id_test,
        id_question,
        Question(
        description,
        optionA,
        optionB,
        optionC,
        optionD,
        optionCorrect
        )
    )

    _add_a_questions(id_test, id_question + 1, dquestions_len - 1, dquestions + Question.SIZE)
    return ()
end
