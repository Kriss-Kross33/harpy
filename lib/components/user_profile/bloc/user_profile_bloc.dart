import 'dart:async';

import 'package:dart_twitter_api/api/users/user_service.dart';
import 'package:dart_twitter_api/twitter_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harpy/components/user_profile/bloc/user_profile_event.dart';
import 'package:harpy/components/user_profile/bloc/user_profile_state.dart';
import 'package:harpy/core/api/twitter/user_data.dart';
import 'package:harpy/core/service_locator.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({
    this.user,
    String userId,
  }) : assert(user != null || userId != null) {
    if (user == null && userId != null) {
      add(LoadUserEvent(userId));
    }
  }

  /// The [UserData] for the user to display.
  UserData user;

  final UserService userService = app<TwitterApi>().userService;

  static UserProfileBloc of(BuildContext context) =>
      BlocProvider.of<UserProfileBloc>(context);

  @override
  UserProfileState get initialState =>
      user == null ? LoadingUserState() : InitializedState();

  @override
  Stream<UserProfileState> mapEventToState(
    UserProfileEvent event,
  ) async* {
    yield* event.applyAsync(currentState: state, bloc: this);
  }
}
