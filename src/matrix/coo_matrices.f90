module coo_matrices

use sparse_matrices
use coo_graphs

implicit none



!--------------------------------------------------------------------------!
type, extends(sparse_matrix) :: coo_matrix                                 !
!--------------------------------------------------------------------------!
    real(dp), allocatable :: val(:)
    class(coo_graph), pointer :: g
contains
    procedure :: init => coo_matrix_init
    procedure :: neighbors => coo_matrix_neighbors
    procedure :: get_value => coo_get_value
    procedure :: set_value => coo_set_value
    procedure :: add_value => coo_add_value
    procedure :: sub_matrix_add => coo_sub_matrix_add
    procedure :: left_permute => coo_left_permute
    procedure :: right_permute => coo_right_permute
    procedure :: matvec => coo_matvec
    procedure :: matvec_t => coo_matvec_t
    procedure, private :: coo_set_value_not_preallocated
end type coo_matrix




contains





!--------------------------------------------------------------------------!
subroutine coo_matrix_init(A,nrow,ncol,orientation,g)                      !
!--------------------------------------------------------------------------!
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: nrow, ncol
    character(len=3), intent(in) :: orientation
    class(graph), pointer, intent(in), optional :: g

    A%nrow = nrow
    A%ncol = ncol
    A%orientation = orientation

    if (present(g)) then
        select type(g)
            class is(coo_graph)
                A%g => g
            class default
                print *, 'Structure graph g of COO matrix A must be '
                print *, 'a COO graph. Exiting.'
                call exit(1)
        end select

        A%nrow = g%n
        A%ncol = g%n
    else
        allocate(coo_graph::A%g)
        call A%g%init(nrow,ncol)
    endif

    A%nnz = A%g%ne
    allocate(A%val(A%nnz))
    A%max_degree = A%g%max_degree

end subroutine coo_matrix_init



!--------------------------------------------------------------------------!
subroutine coo_matrix_neighbors(A,i,nbrs)                                  !
!--------------------------------------------------------------------------!
    class(coo_matrix), intent(in) :: A
    integer, intent(in)  :: i
    integer, intent(out) :: nbrs(:)

    nbrs = 0
    call A%g%neighbors(i,nbrs)

end subroutine coo_matrix_neighbors



!--------------------------------------------------------------------------!
function coo_get_value(A,i,j)                                              !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(in) :: A
    integer, intent(in) :: i,j
    real(dp) :: coo_get_value
    ! local variables
    integer :: k

    coo_get_value = 0.0_dp
    k = A%g%find_edge(i,j)
    if (k/=-1) coo_get_value = A%val(k)

end function coo_get_value



!--------------------------------------------------------------------------!
subroutine coo_set_value(A,i,j,val)                                        !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: i,j
    real(dp), intent(in) :: val
    ! local variables
    integer :: k

    k = A%g%find_edge(i,j)
    if (k/=-1) then
        A%val(k) = val
    else
        call A%coo_set_value_not_preallocated(i,j,val)
    endif

end subroutine coo_set_value



!--------------------------------------------------------------------------!
subroutine coo_add_value(A,i,j,val)                                        !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: i,j
    real(dp), intent(in) :: val
    ! local variables
    integer :: k

    k = A%g%find_edge(i,j)
    if (k/=-1) then
        A%val(k) = A%val(k)+val
    else
        call A%coo_set_value_not_preallocated(i,j,val)
    endif

end subroutine coo_add_value



!--------------------------------------------------------------------------!
subroutine coo_sub_matrix_add(A,B)                                         !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(inout) :: A
    class(sparse_matrix), intent(in) :: B
    ! local variables
    integer :: i,j,k,indx

    do k=1,A%nnz
        i = A%g%edges(1,k)
        j = A%g%edges(2,k)
        A%val(k) = A%val(k)+B%get_value(i,j)
    enddo

end subroutine coo_sub_matrix_add



!--------------------------------------------------------------------------!
subroutine coo_left_permute(A,p)                                           !
!--------------------------------------------------------------------------!
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: p(:)

    call A%g%left_permute(p)

end subroutine coo_left_permute



!--------------------------------------------------------------------------!
subroutine coo_right_permute(A,p)                                          !
!--------------------------------------------------------------------------!
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: p(:)

    call A%g%right_permute(p)

end subroutine coo_right_permute



!--------------------------------------------------------------------------!
subroutine coo_matvec(A,x,y)                                               !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(in) :: A
    real(dp), intent(in)  :: x(:)
    real(dp), intent(out) :: y(:)
    ! local variables
    integer :: i,j,k

    y = 0.0_dp
    do k=1,A%nnz
        i = A%g%edges(1,k)
        j = A%g%edges(2,k)
        y(i) = y(i)+A%val(k)*x(j)
    enddo

end subroutine coo_matvec




!--------------------------------------------------------------------------!
subroutine coo_matvec_t(A,x,y)                                             !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(in) :: A
    real(dp), intent(in)  :: x(:)
    real(dp), intent(out) :: y(:)
    ! local variables
    integer :: i,j,k

    do k=1,A%nnz
        i = A%g%edges(2,k)
        j = A%g%edges(1,k)
        y(i) = y(i)+A%val(k)*x(j)
    enddo

end subroutine coo_matvec_t



!--------------------------------------------------------------------------!
subroutine coo_set_value_not_preallocated(A,i,j,val)                       !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_matrix), intent(inout) :: A
    integer, intent(in) :: i,j
    real(dp), intent(in) :: val
    ! local variables
    real(dp) :: val_temp(A%nnz)

    call A%g%add_edge(i,j)
    val_temp = A%val
    deallocate(A%val)
    allocate(A%val(A%nnz+1))
    A%val(1:A%nnz) = val_temp
    A%val(A%nnz+1) = val
    A%nnz = A%nnz+1
    A%max_degree = A%g%max_degree

end subroutine coo_set_value_not_preallocated



end module coo_matrices