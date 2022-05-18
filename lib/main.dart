import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample_widyaedu/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _ctrl = TextEditingController();

  final moviesRef = FirebaseFirestore.instance
      .collection('notes')
      .withConverter<Note?>(
        fromFirestore: (snapshots, _) =>
            snapshots.data == null ? null : Note.fromJson(snapshots.data()!),
        toFirestore: (note, _) => note!.toJson(),
      );

  @override
  void dispose() {
    _ctrl?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: moviesRef == null
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : StreamBuilder<QuerySnapshot<Note?>>(
                      stream: moviesRef.snapshots(),
                      builder: (ctx, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              snapshot.error?.toString() ?? 'Error',
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final data = snapshot.requireData;
                        return ListView.builder(
                          itemCount: data.size,
                          shrinkWrap: true,
                          itemBuilder: (ctx, index) {
                            if (data.docs[index].data() == null) {
                              return Container();
                            }
                            return NoteItem(
                              callerContext: context,
                              id: data.docs[index].id,
                              note: data.docs[index].data()!,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan note...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                MaterialButton(
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  height: 56.0,
                  padding: const EdgeInsets.all(4.0),
                  color: Colors.blue,
                  onPressed: () async {
                    final note = _ctrl.text;

                    final noteObj = Note(
                      note: note,
                    );
                    final noteJson = noteObj.toJson();

                    FirebaseFirestore.instance
                        .collection('notes')
                        .add(noteJson);

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note added!')));

                    _ctrl.clear();
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 16.0,
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class Note {
  Note({
    required this.note,
  });

  Note.fromJson(Map<String?, Object?>? json)
      : this(
          note: json?['note'] as String?,
        );

  final String? note;

  Map<String, Object?> toJson() {
    return {
      'note': note,
    };
  }
}

class NoteItem extends StatelessWidget {
  const NoteItem({
    Key? key,
    required this.callerContext,
    required this.id,
    required this.note,
  }) : super(key: key);

  final BuildContext callerContext;
  final String id;
  final Note note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onLongPress: () async {
        await FirebaseFirestore.instance.collection('notes').doc(id).delete();
        ScaffoldMessenger.of(callerContext)
            .showSnackBar(const SnackBar(content: Text('Note deleted!')));
      },
      title: Text(
        note.note ?? '',
      ),
    );
  }
}
