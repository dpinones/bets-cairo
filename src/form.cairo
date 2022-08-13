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
from starkware.cairo.common.hash import hash2

#
# Constants
#

const STATUS_OPEN = 'OPEN'
const STATUS_READY = 'READY'
const STATUS_CLOSE = 'CLOSE'

#
# Events
#

@event
func FormCreated(id_form: felt):
end

@event
func SendPoint(id_form: felt, point: felt):
end

#
# Struct
#

struct Form:
    member id: felt
    member name: felt
    member created_at: felt
    member status: felt
    member secret_hash: felt
    member secret: felt
end

struct Question:
    member description: felt
    member optionA: felt
    member optionB: felt
    member optionC: felt
    member optionD: felt
    member option_correct_hash: felt
end

struct Row:
    member user: felt
    member nickname: felt
    member score: felt
end

#
# Storage
#

### FORM ###

#lista de form
@storage_var
func forms(id_form: felt) -> (form: Form):
end

#cantidad de form
@storage_var
func forms_count() -> (count: felt):
end

### QUESTION ###

#lista de preguntas
@storage_var
func questions(id_form: felt, id_question: felt) -> (question: Question):
end

#cantidad de preguntas por form
@storage_var
func questions_count(id_form: felt) -> (questions_count: felt):
end

#respuestas correctas por form / de uso interno
@storage_var
func correct_form_answers(id_form: felt, id_question: felt) -> (correct_form_answer: felt):
end

### USERS ###

# respuesta nro por form / forma de obtener la lista de usuarios por form
@storage_var
func users_form(id_form: felt, id_answer: felt) -> (user: felt):
end

#cantidad de usuarios por form
@storage_var
func count_users_form(id_form: felt) -> (count_users: felt):
end

#cantidad de foms por usuario
@storage_var
func count_forms_by_user(user_address: felt) -> (count_forms: felt):
end

#usuarios que hicieron el form / boolean
@storage_var
func check_users_form(user_address: felt, id_form: felt) -> (bool: felt):
end

#usuarios que hicieron el form / nickname
@storage_var
func nickname_users_form(user_address: felt, id_form: felt) -> (nickname: felt):
end

#puntos de un usuario por form
@storage_var
func points_users_form(user_address: felt, id_form: felt) -> (points: felt):
end

#respuestas de un usuario por form
@storage_var
func answer_users_form(user_address: felt, id_form: felt, id_question : felt) -> (
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
func view_form{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt
) -> (form: Form):
    let (res: Form) = forms.read(id_form)
    return (res)
end

@view
func view_count_forms_by_user{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address: felt
) -> (res: felt):
    let (count_users_form: felt) = count_forms_by_user.read(user_address)
    return (count_users_form)
end

@view
func view_my_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address: felt
) -> (records_len: felt, records: Form*):
    alloc_locals
    let (count: felt) = forms_count.read()
    let (records: Form*) = alloc()
    _recurse_my_forms(user_address, 0, count, records, 0)
    let (count_forms) = count_forms_by_user.read(user_address)
    return (count_forms, records)
end

@view
func view_form_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    count : felt
):
    let (count) = forms_count.read()
    return (count)
end

@view
func view_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt
) -> (records_len : felt, records : Question*):
    alloc_locals

    let (records : Question*) = alloc()
    let (count_question) = questions_count.read(id_form)
    _recurse_view_question_dto(id_form, count_question, records, 0)

    return (count_question, records)
end

@view
func view_question_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt
) -> (question_count : felt):
    let (count) = questions_count.read(id_form)
    return (count)
end

@view
func view_users_form_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt
) -> (count_user : felt):

    let (count) = count_users_form.read(id_form)
    return (count)
end

@view
func view_score_form{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt
) -> (records_len : felt, records : Row*):
    alloc_locals

    # let (records : (felt, felt)*) = alloc()
    let (records : Row*) = alloc()
    let (count) = count_users_form.read(id_form)
    _recurse_view_answers_records(id_form, count, records, 0)

    return (count, records)
end

@view
func view_score_form_user{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt, user: felt
) -> (point: felt):
    let (point) = points_users_form.read(user, id_form)
    return (point)
end

#
# Externals
#

# @external
# func create_form{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     name : felt
# ) -> (id_form: felt):
#     #create form
#     alloc_locals
#     let (local id_form) = _create_form(name)
#     _add_count_user_forms()
#     FormCreated.emit(id_form)
#     return (id_form)
# end

@external
func create_form_add_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    name: felt,
    dquestions_len: felt,
    dquestions: Question*,
    status_open: felt,
    secret_hash: felt
) -> (id_form: felt):
    #create form
    alloc_locals

    let (local id_form) = _create_form(name, secret_hash)

    #add questions
    _add_questions(id_form, dquestions_len, dquestions)

    # close form
    if status_open == 0:
        _change_status_ready_form(id_form, name, secret_hash)
    end
    _add_count_user_forms()

    FormCreated.emit(id_form)
    return (id_form)
end

# @external
# func add_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     id_form : felt,
#     dquestions_len : felt,
#     dquestions : Question*,
#     status_open : felt
# ) -> ():
#     #create form
#     alloc_locals

#     #add questions
#     _add_questions(id_form, dquestions_len, dquestions)
    
#     # close form
#     if status_open == 0:
#         let (form: Form) = forms.read(id_form)
#         _change_status_ready_form(id_form, form.name)
#     end

#     FormCreated.emit(id_form)
#     return ()
# end

@external
func forms_change_status_ready{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt
) -> ():
    let (form: Form) = forms.read(id_form)
    _change_status_ready_form(id_form, form.name, form.secret_hash)
    return ()
end

@external
func send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt, nickname: felt, answers_len: felt, answers: felt*
) -> ():
    alloc_locals

    let (count) = forms_count.read()
    with_attr error_message("Form not found"):
        assert_in_range(id_form + 1 , 0, count +1)
    end

    let (count_question) = questions_count.read(id_form)
    with_attr error_message("Length of answers must be equal to the number of questions"):
        assert answers_len = count_question
    end

    let (caller_address) = get_caller_address()
    let (bool) = check_users_form.read(caller_address, id_form)
    with_attr error_message("You have already answered this form"):
        assert bool = FALSE
    end

    # guardo la respuesta del usuario
    _recurse_add_answers(id_form, count_question, answers, 0, caller_address)

###### ESTAS VARIABLES CAPAZ SE PUEDEN UNIFICAR
    # guardo que el usuario ya realizo el form    
    check_users_form.write(caller_address, id_form, TRUE)

    nickname_users_form.write(caller_address, id_form, nickname)
    
    let (count_users) = count_users_form.read(id_form)
    # guardo que usuario hizo tal form
    users_form.write(id_form, count_users, caller_address)
######

    #cantidad de usuarios por form
    count_users_form.write(id_form, count_users + 1)

    return ()
end

@external
func close_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt,
    secret: felt
) -> ():
    alloc_locals
    let (form: Form) = forms.read(id_form)

    # verifico que el secreto sea el mismo que el que se creo el form
    # hash(secret) == form.secret_hash
    let (hash) = hash2{hash_ptr=pedersen_ptr}(secret, 0)
    assert hash = form.secret_hash

    #obtengo cantidad de usuarios que hicieron el form
    let (count_users) = count_users_form.read(id_form)
    #obtengo cantidad de preguntas por form
    let (count_question) = questions_count.read(id_form)

    _close_forms(id_form, count_users, count_question, secret)

    # CERRAR EL FORM
    _change_status_close_form(id_form, form.name, form.secret_hash, secret)

    return ()
end

#calculo los puntos de un formulario
func _close_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt,
    count_users: felt,
    count_question: felt, 
    secret: felt
) -> ():
    alloc_locals
    if count_users == 0:
        return ()
    end

    #obtener el usuario
    let (user) = users_form.read(id_form, count_users - 1)
    #obtener los puntos del usuario
    let (point) = _calculate_score(id_form, count_question, 0, user, secret)

    # guardo puntos de usuario en form
    points_users_form.write(user, id_form, point)

    _close_forms(id_form, count_users - 1, count_question, secret)
    return ()
end

#calcula puntos de un usuario
func _calculate_score{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt, 
    count_answer: felt, 
    idx: felt, 
    caller_address: felt,
    secret: felt
) -> (points: felt):
    alloc_locals
    if count_answer == 0:
        return (0)
    end

    # respuesta correcta 
    let (option_correct_hash) = correct_form_answers.read(id_form, idx)

    # respuesta del usuario
    let (answer_user_id) = answer_users_form.read(caller_address, id_form, idx)
    let (question: Question) = questions.read(id_form, idx)
    let (answer_user) = _get_answer_for_id(question, answer_user_id)

    # hash(answer_user, secret) == option_correct_hash

    # si la respuesta es correcta
    let (answer_user_hash) = hash2{hash_ptr=pedersen_ptr}(answer_user, secret)
    local t
    if answer_user_hash == option_correct_hash:
        t = 5
    else:
        t = 0
    end
    let (local total) = _calculate_score(id_form, count_answer - 1, idx + 1, caller_address, secret)
    let res = t + total
    return (res)
end

#
# Internal
#

func _create_form{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    secret_hash: felt
) -> (id_form : felt):

    let (id_form) = forms_count.read()
    let (caller_address) = get_caller_address()
    forms.write(id_form, Form(id_form, name, caller_address, STATUS_OPEN, secret_hash, 0))
    forms_count.write(id_form + 1)
    return (id_form)
end

func _change_status_ready_form{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id_form: felt, 
    name: felt,
    secret_hash: felt
) -> ():
    let (caller_address) = get_caller_address()
    forms.write(id_form, Form(id_form, name, caller_address, STATUS_READY, secret_hash, 0))
    return ()
end

func  _change_status_close_form{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    id_form: felt, 
    name: felt,
    secret_hash: felt,
    secret: felt
) -> ():
    let (caller_address) = get_caller_address()
    forms.write(id_form, Form(id_form, name, caller_address, STATUS_CLOSE, secret_hash, secret))
    return ()
end

func _add_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt,
    dquestions_len: felt,
    dquestions : Question*
) -> ():
    alloc_locals
    #len > 0
    assert_le(0, dquestions_len)

    let (count_question) = questions_count.read(id_form)
    _add_a_questions(id_form, count_question, dquestions_len, dquestions)

    questions_count.write(id_form, count_question + dquestions_len)

    return ()
end

func _add_count_user_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    let (caller_address: felt) = get_caller_address()
    let (count: felt) = count_forms_by_user.read(caller_address)
    count_forms_by_user.write(caller_address, count + 1)
    return ()
end

func _recurse_my_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address: felt,
    index: felt,
    len: felt,
    arr: Form*,
    idx: felt
) -> ():
    if index == len:
        return ()
    end

    let (form: Form) = forms.read(index)
    if  form.created_at == user_address:
        # assert arr[idx] = form
        assert arr[idx] = Form(form.id, form.name, form.created_at, form.status, form.secret_hash, form.secret)
        _recurse_my_forms(user_address, index + 1, len, arr, idx + 1)
        return ()
    else:
        _recurse_my_forms(user_address, index + 1, len , arr, idx)
        return ()
    end
end

func _recurse_view_question{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(id_form : felt, len : felt, arr : Question*, idx : felt) -> ():
    if idx == len:
        return ()
    end

    let (record : Question) = questions.read(id_form, idx)
    assert arr[idx] = Question(record.description, record.optionA, record.optionB, record.optionC, record.optionD, record.option_correct_hash)

    _recurse_view_question(id_form, len, arr, idx + 1)
    return ()
end

func _recurse_view_question_dto{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(id_form : felt, len : felt, arr : Question*, idx : felt) -> ():
    if idx == len:
        return ()
    end

    let (record : Question) = questions.read(id_form, idx)
    assert arr[idx] = Question(record.description, record.optionA, record.optionB, record.optionC, record.optionD, record.option_correct_hash)

    _recurse_view_question_dto(id_form, len, arr, idx + 1)
    return ()
end


func _recurse_view_answers_records{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(id_form : felt, len : felt, arr : Row*, idx : felt) -> ():
    if idx == len:
        return ()
    end

    let (user: felt) = users_form.read(id_form, idx)
    let (point) = points_users_form.read(user, id_form)
    let (nickname) = nickname_users_form.read(user, id_form)
    assert arr[idx] = Row(user, nickname, point)

    _recurse_view_answers_records(id_form, len, arr, idx + 1)
    return ()
end

func _recurse_add_answers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form : felt, len : felt, arr : felt*, idx : felt, caller_address: felt
) -> ():
    alloc_locals
    if len == 0:
        return ()
    end

    # respuesta del usuario
    tempvar answer_user : felt
    answer_user = cast([arr], felt)
    
    # 0 >= answer <= 3
    with_attr error_message("The option must be between 0 and 3"):
        assert_in_range(answer_user, 0, 4)
    end
    
    # guardo la respuesta del usuario
    answer_users_form.write(caller_address, id_form, idx, answer_user)

    _recurse_add_answers(id_form, len - 1, arr + 1, idx + 1, caller_address)
    return ()
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
    id_form : felt,
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
    let option_correct_hash = [dquestions].option_correct_hash
    
    # with_attr error_message("Option correct must be between 0 and 3"):
    #     assert_in_range(option_correct_hash, 0, 4)
    # end

    correct_form_answers.write(id_form, id_question, option_correct_hash)

    questions.write(
        id_form,
        id_question,
        Question(
        description,
        optionA,
        optionB,
        optionC,
        optionD,
        option_correct_hash
        )
    )

    _add_a_questions(id_form, id_question + 1, dquestions_len - 1, dquestions + Question.SIZE)
    return ()
end


@external
func remove_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt,
    id_question_remove: felt
) -> ():
    #create form
    alloc_locals

    # empezar a pisar las preguntas a partir del index id_question
    
    # - cantidad de preguntas
    let (count_question) = questions_count.read(id_form)

    # eliminar pregunta
    _remove_questions(id_form, id_question_remove, 0, 0, count_question)
    
    # restar uno a la cantidad de preguntas
    questions_count.write(id_form, count_question - 1)

    # close form
    FormCreated.emit(id_form)
    return ()
end

func _remove_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id_form: felt, id_question_remove: felt, id_question:felt, idx: felt, count: felt
) -> ():
    if count == 0:
        return ()
    end

    if id_question == id_question_remove:
        _remove_questions(id_form, id_question_remove, id_question + 1, idx, count - 1)
        return ()
    else:
        let (question: Question) = questions.read(id_form, id_question)
        questions.write(
            id_form,
            idx,
            Question(
            question.description,
            question.optionA,
            question.optionB,
            question.optionC,
            question.optionD,
            question.option_correct_hash
            )
        )
        _remove_questions(id_form, id_question_remove,  id_question + 1, idx + 1, count - 1)
        return ()
    end
end