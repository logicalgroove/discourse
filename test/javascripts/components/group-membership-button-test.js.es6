moduleFor('component:group-membership-button');

test('canJoinGroup', function() {
  this.subject().setProperties({
    model: { public: false }
  });

  equal(this.subject().get("canJoinGroup"), false, "non public group cannot be joined");

  this.subject().set("model.public", true);

  equal(this.subject().get("canJoinGroup"), true, "public group can be joined");

  this.subject().setProperties({ currentUser: null, model: { public: true } });

  equal(this.subject().get("canJoinGroup"), true, "can't join group when not logged in");
});

test('userIsGroupUser', function() {
  this.subject().setProperties({
    model: { is_group_user: true }
  });

  equal(this.subject().get('userIsGroupUser'), true);

  this.subject().set('model.is_group_user', false);

  equal(this.subject().get('userIsGroupUser'), false);

  this.subject().setProperties({ model: { id: 1 }, groupUserIds: [1] });

  equal(this.subject().get('userIsGroupUser'), true);

  this.subject().set('groupUserIds', [3]);

  equal(this.subject().get('userIsGroupUser'), false);

  this.subject().set('groupUserIds', undefined);

  equal(this.subject().get('userIsGroupUser'), false);

  this.subject().setProperties({
    groupUserIds: [1, 3],
    model: { id: 1, is_group_user: false }
  });

  equal(this.subject().get('userIsGroupUser'), false);
});
