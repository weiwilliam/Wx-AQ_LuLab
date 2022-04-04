program prepbufr_append_surface
!
!  append a surface observation into prepbufr file
!
 implicit none

 integer, parameter :: mxmn=35, mxlv=1
 character(80):: hdstr='SID XOB YOB DHR TYP ELV SAID T29'
 character(80):: obstr='POB QOB TOB ZOB UOB VOB PWO CAT PRSS'
 character(80):: qcstr='PQM QQM TQM ZQM WQM NUL PWQ     '
 character(80):: oestr='POE QOE TOE NUL WOE NUL PWE     '
 real(8) :: hdr(mxmn),obs(mxmn,mxlv),qcf(mxmn,mxlv),oer(mxmn,mxlv)

 character(8) :: subset
 integer      :: unit_out=10,unit_table=20,unit_tmp=30,idate,iret

 character(8) :: c_sid
 real(8)      :: rstation_id
 equivalence(rstation_id,c_sid)

 character(8) :: prvstr,sprvstr
 character(8) :: c_prvstg,c_sprvstg
 real(8) :: r_prvstg(1,1),r_sprvstg(1,1)
 equivalence(r_prvstg(1,1),c_prvstg)
 equivalence(r_sprvstg(1,1),c_sprvstg)
 data prvstr /'PRVSTG'/
 data sprvstr /'SPRVSTG'/

 integer :: i, obsnum, readerrstat
 character(len=10) :: CDATE!, ID, LAT, LON, DHR, ELE, &
                      !P, T, Q, U, V
 integer :: CTIME
 character(len=4), allocatable, dimension(:) :: NYSM_ID
 real(8), allocatable, dimension(:) :: NYSM_LAT, NYSM_LON, &
                                       NYSM_DHR, NYSM_ELE, NYSM_P, &
                                       NYSM_T, NYSM_Q, NYSM_U, NYSM_V


! get NYSM observations as input arguments
 call getarg( 1,CDATE)
! call getarg( 2,ID)
! call getarg( 3,LAT)
! call getarg( 4,LON)
! call getarg( 5,ELE)
! call getarg( 6,DHR)
! call getarg( 7,P)
! call getarg( 8,T)
! call getarg( 9,Q)
! call getarg(10,U)
! call getarg(11,V)
!
 read(CDATE,'(i10)') CTIME
! NYSM_ID=trim(ID)
! read(LAT,'(f10.2)') NYSM_LAT
! read(LON,'(f10.2)') NYSM_LON
! read(ELE,'(f10.1)') NYSM_ELE
! read(DHR,'(f10.1)') NYSM_DHR
! read(P,'(f10.2)') NYSM_P
! read(T,'(f10.1)') NYSM_T
! read(Q,'(f10.1)') NYSM_Q
! read(U,'(f10.1)') NYSM_U
! read(V,'(f10.1)') NYSM_V

! get NYSM observations from ./intermediate.csv
 open(unit_tmp,file='./intermediate.csv',status='old', &
      form='formatted',access='sequential')
 obsnum=0
 readerrstat=0
 do while (readerrstat .eq. 0 )
    read(unit_tmp,*,iostat=readerrstat)
    if (readerrstat .ne. 0) exit
    obsnum=obsnum+1
 end do
 !write(6,*) 'obs counts=',obsnum

 allocate( NYSM_ID(obsnum),NYSM_LAT(obsnum),NYSM_LON(obsnum), &
          NYSM_ELE(obsnum),NYSM_DHR(obsnum),  NYSM_P(obsnum), &
            NYSM_T(obsnum),  NYSM_Q(obsnum),  NYSM_U(obsnum), &
            NYSM_V(obsnum))
 rewind(unit_tmp)

 do i=1,obsnum
    read(unit_tmp,*) NYSM_ID(i),NYSM_LAT(i),NYSM_LON(i),NYSM_ELE(i), &
                     NYSM_DHR(i),NYSM_P(i),NYSM_T(i),NYSM_Q(i),NYSM_U(i),NYSM_V(i)
 end do
 close(unit_tmp)

! get bufr table from existing bufr file
 open(unit_table,file='prepbufr.table')
 open(unit_out,file='prepbufr',status='old',form='unformatted')
 call openbf(unit_out,'IN',unit_out)
 call dxdump(unit_out,unit_table)
 call closbf(unit_out)
!
! write observation into prepbufr file
!
 open(unit_out,file='prepbufr',status='old',form='unformatted')
 call datelen(10)
 call openbf(unit_out,'APN',unit_table)

   idate=CTIME ! cycle time: YYYYMMDDHH
   subset='MSONET'  ! surface land (SYNOPTIC, METAR) reports
   call openmb(unit_out,subset,idate)

   do i=1,obsnum

! set headers
      hdr=10.0e10
      c_sid=NYSM_ID(i); hdr(1)=rstation_id
      hdr(2)=NYSM_LON(i); hdr(3)=NYSM_LAT(i); hdr(4)=NYSM_DHR(i); hdr(6)=NYSM_ELE(i)
      c_prvstg='NY-Meso'; c_sprvstg='allsprvs'

! set obs, qcf, oer for  wind
      hdr(5)=288          ! report type
      obs=10.0e10;qcf=10.0e10;oer=10.0e10
      obs(1,1)=NYSM_P(i); obs(5,1)=NYSM_U(i); obs(6,1)=NYSM_V(i); obs(8,1)=6.0
      qcf(1,1)=2.0   ; qcf(5,1)=2.0
      oer(5,1)=2.5
! encode  wind obs
      call ufbint(unit_out,hdr,mxmn,1   ,iret,hdstr)
      call ufbint(unit_out,r_prvstg,1,1 ,iret,prvstr)
      call ufbint(unit_out,r_sprvstg,1,1,iret,sprvstr)
      call ufbint(unit_out,obs,mxmn,mxlv,iret,obstr)
      call ufbint(unit_out,oer,mxmn,mxlv,iret,oestr)
      call ufbint(unit_out,qcf,mxmn,mxlv,iret,qcstr)
      call writsb(unit_out)

! set obs, qcf, oer for  temperature and moisture
      hdr(5)=188          ! report type
      obs=10.0e10;qcf=10.0e10;oer=10.0e10
      obs(1,1)=NYSM_P(i);obs(2,1)=NYSM_Q(i);obs(3,1)=NYSM_T(i);obs(4,1)=NYSM_ELE(i);obs(8,1)=0.0
      qcf(1,1)=2.0   ;qcf(2,1)=2.0   ;qcf(3,1)=2.0 ;qcf(4,1)=2.0
      oer(1,1)=1.6   ;oer(2,1)=2.0   ;oer(3,1)=2.5 
! encode temperature and moisture
      call ufbint(unit_out,hdr,mxmn,1   ,iret,hdstr)
      call ufbint(unit_out,r_prvstg,1,1 ,iret,prvstr)
      call ufbint(unit_out,r_sprvstg,1,1,iret,sprvstr)
      call ufbint(unit_out,obs,mxmn,mxlv,iret,obstr)
      call ufbint(unit_out,oer,mxmn,mxlv,iret,oestr)
      call ufbint(unit_out,qcf,mxmn,mxlv,iret,qcstr)
      call writsb(unit_out)

   end do

   call closmg(unit_out)
 call closbf(unit_out)

end program
