
describe("Array Test Spec", function() {
  //demonstrates use of expected exceptions
  describe("#indexOf", function() {
    it("should find 1 in [1,2,3]", function() {
      expect([1,2,3].indexOf(1)).toEqual(0);
    });
  });

});
describe("Array FAIL Spec", function() {
  //demonstrates use of expected exceptions
  describe("#indexOf", function() {
    it("should find 1 in [2,2,3]", function() {
      expect([2,2,3].indexOf(1)).toEqual(0);
    });
  });

});


