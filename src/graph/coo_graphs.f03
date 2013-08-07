module coo_graphs

use graphs

implicit none



!--------------------------------------------------------------------------!
type, extends(graph) :: coo_graph                                          !
!--------------------------------------------------------------------------!
    integer, allocatable :: edges(:,:)
contains
    procedure :: init => coo_init
    procedure :: neighbors => coo_neighbors
    procedure :: connected => coo_connected
    procedure :: find_edge => coo_find_edge
    procedure :: find_edges => coo_find_edges
    procedure :: add_edge => coo_add_edge
    procedure :: delete_edge => coo_delete_edge
    procedure :: free => coo_free
    procedure :: dump_edges => coo_dump_edges

end type coo_graph





contains



!--------------------------------------------------------------------------!
subroutine coo_init(g,n,m,edges)                                           !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: n
    integer, intent(in), optional :: m, edges(:,:)
    ! local variables
    integer :: i,k,ne,degree(n)

    g%n = n

    if (present(m)) then
        g%m = m
    else
        g%m = n
    endif

    if (present(edges)) then
        ne = size(edges,2)
        g%ne = ne

        degree = 0
        do k=1,ne
            i = edges(1,k)
            degree(i) = degree(i)+1
        enddo
        g%max_degree = maxval(degree)
    else
        ne = 0
        g%ne = ne
        g%max_degree = 0
    endif

    allocate( g%edges(2,ne) )

    if (present(edges)) then
        g%edges = edges
    endif
    
end subroutine coo_init



!--------------------------------------------------------------------------!
subroutine coo_neighbors(g,i,nbrs)                                         !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i
    integer, intent(out) :: nbrs(:)
    ! local variables
    integer :: k,next

    nbrs = 0
    next = 0
    do k=1,g%ne
        if (g%edges(1,k)==i) then
            next = next+1
            nbrs(next) = g%edges(2,k)
        endif
    enddo

end subroutine coo_neighbors



!--------------------------------------------------------------------------!
function coo_connected(g,i,j)                                              !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i,j
    logical :: coo_connected
    ! local variables
    integer :: k

    coo_connected = .false.

    do k=1,g%ne
        if (g%edges(1,k)==i .and. g%edges(2,k)==j) coo_connected = .true.
    enddo

end function coo_connected



!--------------------------------------------------------------------------!
function coo_find_edge(g,i,j)                                              !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: i,j
    integer :: coo_find_edge
    ! local variables
    integer :: k

    coo_find_edge = -1

    do k=1,g%ne
        if (g%edges(1,k)==i .and. g%edges(2,k)==j) coo_find_edge = k
    enddo

end function coo_find_edge



!--------------------------------------------------------------------------!
function coo_find_edges(g,is,js)                                           !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(in) :: g
    integer, intent(in) :: is(:), js(:)
    integer :: coo_find_edges(size(is),size(js))
    ! local variables
    integer :: i,j,k

    coo_find_edges = -1
    do k=1,g%ne
        do j=1,size(js)
            if (js(j)==g%edges(2,k)) then
                do i=1,size(is)
                    if (is(i)==g%edges(1,k)) coo_find_edges(i,j) = k
                enddo
            endif
        enddo
    enddo

end function coo_find_edges



!--------------------------------------------------------------------------!
subroutine coo_add_edge(g,i,j)                                             !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: i,j
    ! local variables
    integer :: k,degree,edges_temp(2,g%ne)

    if (.not.g%connected(i,j)) then
        ! Copy the current edge list into a temporary array
        edges_temp = g%edges

        ! Deallocate the edge list and reallocate it with extra room
        deallocate(g%edges)
        allocate(g%edges(2,g%ne+1))

        ! Copy in the temporary array
        g%edges(:,1:g%ne) = edges_temp

        ! Add in the new edge
        g%edges(:,g%ne+1) = [i, j]

        ! Increase the number of edges
        g%ne = g%ne+1

        ! If the degree of node i is now the greatest of all nodes in the
        ! graph, update the degree accordingly
        degree = 0
        do k=1,g%ne
            if (g%edges(1,k)==i) degree = degree+1
        enddo
        if (degree > g%max_degree) g%max_degree = degree
    endif

end subroutine coo_add_edge



!--------------------------------------------------------------------------!
subroutine coo_delete_edge(g,i,j)                                          !
!--------------------------------------------------------------------------!
    ! input/output variables
    class(coo_graph), intent(inout) :: g
    integer, intent(in) :: i,j
    ! local variables
    integer :: k,l,indx,degree(g%n),edges_temp(2,g%ne)

    if (g%connected(i,j)) then

        ! Find the index in the list of edges of the edge to be removed
        indx = g%find_edge(i,j)

        ! Store the current edge list in a temporary array
        edges_temp = g%edges

        ! Rebuild the edge array with extra space
        ! NOTE: This can probably be done with reallocate to save pain
        deallocate(g%edges)
        allocate(g%edges(2,g%ne-1))

        g%edges(:,1:indx-1) = edges_temp(:,1:indx-1)
        g%edges(:,indx:g%ne-1) = edges_temp(:,indx+1:g%ne)

        ! Decrement the number of edges
        g%ne = g%ne-1

        ! Evaluate the graph's new maximum degree
        degree = 0
        do k=1,g%ne
            l = g%edges(1,k)
            degree(l) = degree(l)+1
        enddo
        g%max_degree = maxval(degree)
    endif

end subroutine coo_delete_edge



!--------------------------------------------------------------------------!
subroutine coo_free(g)                                                     !
!--------------------------------------------------------------------------!
    class(coo_graph), intent(inout) :: g

    deallocate(g%edges)

    g%n = 0
    g%m = 0
    g%ne = 0
    g%max_degree = 0

end subroutine coo_free



!--------------------------------------------------------------------------!
subroutine coo_dump_edges(g,edges)                                         !
!--------------------------------------------------------------------------!
    class(coo_graph), intent(in) :: g
    integer, intent(out) :: edges(:,:)

    edges = g%edges

end subroutine coo_dump_edges



end module coo_graphs
