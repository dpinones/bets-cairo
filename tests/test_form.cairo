%lang starknet

from src.form import Question
from src.form import Form
from src.form import STATUS_OPEN
from src.form import STATUS_READY
from src.form import STATUS_CLOSED

# from src.form import view_form_count
# from src.form import view_form
# from src.form import view_question_count
# from src.form import view_questions
# from src.form import view_users_form_count
# from src.form import view_score_form_user

# from src.form import create_form
# from src.form import forms_change_status_ready
# from src.form import send_answer

# from src.form import _get_answer_for_id
# from src.form import close_forms


from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.hash import hash2

from src.interfaces.IForm import IForm

@external
func test_form_with_ready_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./src/form.cairo", []).contract_address %}


    let (local array: Question*) = alloc() 
    let secret = 'starknet'
    let (secret_hash) = hash2{hash_ptr=pedersen_ptr}(secret, 0)
    let (option_correct_hash) = hash2{hash_ptr=pedersen_ptr}(secret, 'celeste')
    assert array[0] = Question('El cielo es?', 'rojo', 'gris', 'celeste', 'blanco', option_correct_hash)
    let (id_form) = IForm.create_form(
        contract_address=contract_address,
        name='Test 1',
        dquestions_len=1, 
        dquestions=array,
        status_open=0,
        secret_hash=secret_hash
    )

    let (form: Form) = IForm.view_form(
        contract_address=contract_address,
        id_form=id_form
    )
    assert form.name = 'Test 1'
    assert form.status = STATUS_READY
    assert form.secret_hash = secret_hash
    assert form.secret = 0
    
    let (question_count) = IForm.view_question_count(
        contract_address=contract_address,
        id_form=id_form)
    assert question_count = 1
    return ()
end

# @view
# func test_form_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     let (form_count) = view_form_count()
#     assert form_count = 0
#     return ()
# end

# # form with 0 questions
# @view
# func test_form_question_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     let (id_form) = create_form('Starknet')

#     let (form: Form) = view_form(id_form)
#     assert form.name = 'Starknet'
#     assert form.status = STATUS_OPEN

#     let (question_count) = view_question_count(id_form)
#     assert question_count = 0

#     return ()
# end

# form with ready status


# #form with questions and open status and add questions
# @view
# func test_form_add_questions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    
#     alloc_locals
#     let (local array: Question*) = alloc() 
#     assert array[0] = Question(00,11, 22, 33, 44, 1)
#     let (id_form) = create_form_add_questions('starknet', 1, array, 1)

#     let (form: Form) = view_form(id_form)
#     assert form.status = STATUS_OPEN
    
#     let (question_count) = view_question_count(id_form)
#     assert question_count = 1
    
#     let (local qarray: Question*) = alloc() 
#     assert qarray[0] = Question(00,11, 22, 33, 44, 1)
#     add_questions(id_form, 1, qarray, 0)

#     let (form: Form) = view_form(id_form)
#     assert form.status = STATUS_READY
    
#     let (question_count) = view_question_count(id_form)
#     assert question_count = 2

#     return ()
# end

# #form with questions and open status -> ready status
# @view
# func test_forms_change_status_ready{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    
#     alloc_locals
#     let (local array: Question*) = alloc() 
#     assert array[0] = Question(00,11, 22, 33, 44, 1)
#     let (id_form) = create_form_add_questions('starknet', 1, array, 1)

#     let (form: Form) = view_form(id_form)
#     assert form.status = STATUS_OPEN
    
#     let (question_count) = view_question_count(id_form)
#     assert question_count = 1
    
#     forms_change_status_ready(id_form)

#     let (form: Form) = view_form(id_form)
#     assert form.status = STATUS_READY
    
#     let (question_count) = view_question_count(id_form)
#     assert question_count = 1

#     return ()
# end

# #send answer to forms
# @view
# func test_send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     let (local array: Question*) = alloc() 
#     assert array[0] = Question(00,11, 22, 33, 44, 1)
#     let (id_form) = create_form_add_questions('starknet', 1, array, 0)
    
#     let (users_form_count) = view_users_form_count(id_form)
#     assert users_form_count = 0

#     let (local array1 : felt*) = alloc()
#     assert array1[0] = 1
#     send_answer(id_form, 1, array1)

#     let (users_form_count) = view_users_form_count(id_form)
#     assert users_form_count = 1
    
#     return ()
# end

# #calculate points for form
# @view
# func test_close_forms{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     let (local array: Question*) = alloc() 
#     assert array[0] = Question(00,11, 22, 33, 44, 1)
#     let (id_form) = create_form_add_questions('starknet', 1, array, 0)
#     let (local array1 : felt*) = alloc()
#     assert array1[0] = 1
#     send_answer(id_form, 1, array1)

#     close_forms(id_form)
#     let (caller_address) = get_caller_address()
#     let (points) = view_score_form_user(caller_address, id_form)
#     assert points = 5

#     return ()
# end

# # @view
# # func test_send_answer2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
# #     alloc_locals

# #     let (test_id) = create_test(1)
# #     let (local qarray: Question*) = alloc() 
# #     assert qarray[0] = Question(00,11, 22, 33, 44, 1)
# #     assert qarray[1] = Question(00,44, 55, 66, 77, 3)
# #     assert qarray[2] = Question(00,99, 00, 11, 22, 2)

# #     add_questions(test_id, 3, qarray)
    
# #     ready_test(test_id)
    
# #     let (local array : felt*) = alloc()
# #     assert array[0] = 1
# #     assert array[1] = 1
# #     assert array[2] = 1
# #     send_answer(test_id, 3, array)

# #     let (caller_address) = get_caller_address()
# #     let (points) = view_points_user_test(caller_address, test_id)
# #     assert points = 5
    
# #     return ()
# # end