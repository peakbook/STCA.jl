using STCA
using Base.Test

@test STCA.tostr(0x3031_3233)=="0123"
@test STCA.tostr(0x3031_3233_3435_3637)=="01234567"
@test STCA.toval32("0123")==0x3031_3233
@test STCA.toval64("01234567")==0x3031_3233_3435_3637

@test STCA.rotate(0x11223344)==0x44112233
@test STCA.rotate(0x11223344_55667788)==0x44112233_88556677

@test STCA.north(0x11223344)==0x11
@test STCA.east(0x11223344)==0x22
@test STCA.south(0x11223344)==0x33
@test STCA.west(0x11223344)==0x44

d = [
0xaaaaaaaa 0xffff33ff 0xbbbbbbbb;
0xff22ffff 0xeeeeeeee 0xffffff44;
0xcccccccc 0x11ffffff 0xdddddddd
]
sd = view(d,1:3,1:3)
@test STCA.qn(sd)==0x33
@test STCA.qe(sd)==0x44
@test STCA.qs(sd)==0x11
@test STCA.qw(sd)==0x22
@test STCA.get_target_state(sd)==0xeeeeeeee_33441122
STCA.set_target_state(sd,0xffffffff_11223344)
@test STCA.get_target_state(sd)==0xffffffff_11223344

STCA.qn!(sd,0x0000_00ff)
@test d[4]==0xffff_ffff
STCA.qe!(sd,0x0000_00ff)
@test d[8]==0xffff_ffff
STCA.qs!(sd,0x0000_00ff)
@test d[6]==0xffff_ffff
STCA.qw!(sd,0x0000_00ff)
@test d[2]==0xffff_ffff

