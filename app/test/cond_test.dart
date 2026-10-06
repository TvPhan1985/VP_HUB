import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/cond.dart';

void main() {
  final v = <String, dynamic>{
    'mode': 'manual',
    'alarm': 0,
    'latched': true,
    'out': 1,
    'src': 'schedule',
    'n': 2.5,
    'none': null,
  };

  test('== voi chuoi, so, bool', () {
    expect(evalCond('mode==manual', v), isTrue);
    expect(evalCond('mode==auto', v), isFalse);
    expect(evalCond('alarm==0', v), isTrue);
    expect(evalCond('alarm==1', v), isFalse);
    expect(evalCond('latched==true', v), isTrue);
    expect(evalCond('latched==false', v), isFalse);
    expect(evalCond('n==2.5', v), isTrue);
    expect(evalCond('none==null', v), isTrue);
  });

  test('!=', () {
    expect(evalCond('alarm!=0', v), isFalse);
    expect(evalCond('alarm!=0', {'alarm': 4}), isTrue);
    expect(evalCond('src!=schedule', v), isFalse);
    expect(evalCond('src!=sensor', v), isTrue);
  });

  test('bool chap nhan 0/1 o ca hai phia', () {
    expect(evalCond('out==true', v), isTrue);
    expect(evalCond('out==false', v), isFalse);
    expect(evalCond('latched==1', v), isTrue);
    expect(evalCond('latched!=1', v), isFalse);
  });

  test('&& noi nhieu dieu kien', () {
    expect(evalCond('mode==manual&&alarm==0', v), isTrue);
    expect(evalCond('mode==manual && alarm!=0', v), isFalse);
    expect(evalCond('mode==auto&&alarm==0', v), isFalse);
    expect(evalCond('mode==manual&&alarm==0&&latched==true', v), isTrue);
  });

  test('thieu truong trong VALUES thi coi la dung', () {
    expect(evalCond('khongco==1', v), isTrue);
    expect(evalCond('khongco!=1', v), isTrue);
    expect(evalCond('khongco==1&&mode==manual', v), isTrue);
    expect(evalCond('khongco==1&&mode==auto', v), isFalse);
  });

  test('rong, null, sai cu phap thi coi la dung', () {
    expect(evalCond(null, v), isTrue);
    expect(evalCond('', v), isTrue);
    expect(evalCond('mode', v), isTrue);
    expect(evalCond('==x', v), isTrue);
  });

  test('gia tri co dau nhay', () {
    expect(evalCond('mode=="manual"', v), isTrue);
    expect(evalCond("mode=='auto'", v), isFalse);
  });

  test('renameCond chi doi id co trong bang', () {
    expect(renameCond('en==true&&mode!=off', {'en': 's1_en'}), 's1_en==true&&mode!=off');
    expect(renameCond(null, {'en': 's1_en'}), isNull);
  });
}
