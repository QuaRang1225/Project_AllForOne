//
//  PokemonInfoViewModel.swift
//  PokeDex_Project
//
//  Created by 유영웅 on 2023/05/22.
//

import Foundation
import PokemonAPI

class PokemonInfoViewModel:ObservableObject{
    
    
    
    @Published var image = String() //이미지
    @Published var name = String()  //이름
    @Published var genera = String()    //타이틀
    @Published var height = Int()   //키
    @Published var weight = Int()   //몸무게
    @Published var eggGroup = [String]()    //알그룹
    @Published var gender = [Double]()  //성비
    @Published var get = Int()  //포획률
    @Published var char = [String]()    //특성
    @Published var charDesc = [String]()    //특성 설명
    @Published var hiddenChar = [String]()  //숨겨진 특성
    @Published var hiddenCharDesc = [String]()  //숨겨진특성 설명
    @Published var types = [String]()   //타입
    
    //스탯
    @Published var hp = [Int]()
    @Published var attack = [Int]()
    @Published var defense = [Int]()
    @Published var spAttack = [Int]()
    @Published var spDefense = [Int]()
    @Published var speed = [Int]()
    @Published var avr = [Int]()
    
    //진화트리 - 포켓몬 이미지
    @Published var first = [String]()
    @Published var second = [String]()
    @Published var third = [String]()
    @Published var forth = [String]()
    //진화트리 - 포켓몬 이름
    @Published var firstName = [String]()
    @Published var secondName = [String]()
    @Published var thirdName = [String]()
    @Published var forthName = [String]()
    
    @Published var desc = [String]()    //도감설명
    
    @Published var isRegion = [Int]()
    @Published var isRegionName = [String]()
    @Published var mega = [String]()
    
    func urlToInt(url:String)->Int{ //포켓몬 이미지를 얻기 위한 url에서 코드 추출
        let url = Int(String(url.filter({$0.isNumber}).dropFirst()))!
        return url
    }
    private func imageUrl(url:Int)->String{ //이미지 url저장
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(url).png"
    }
    func getKoreanName(num: Int) async -> String {  //포켓몬 코드 -> 한글명(이름)
        let species = try? await PokemonAPI().pokemonService.fetchPokemonSpecies(num)
        guard let names = species?.names else { return "" }
        
        for i in names {
            guard let name = i.language?.name else { continue }
            if name == "ko" {
                return i.name ?? ""
            }
        }
        return ""
    }
    func getKoreanType(num:Int) async -> [String]{    //포켓몬 코드 -> 한글명(타입)
        var koreanType = [String]()
        let pokemon = try? await PokemonAPI().pokemonService.fetchPokemon(num)
        if let types = pokemon?.types{
            for type in types {
                let type = try? await PokemonAPI().pokemonService.fetchType(urlToInt(url: (type.type?.url)!))
                koreanType.append(type?.names![1].name ?? "")
            }
        }
        return koreanType
    }
    
    @MainActor
    func getSpecies(num:Int){  //포켓몬 정보 요청
        
        
        self.name.removeAll()
        self.desc.removeAll()
        self.genera.removeAll()
        self.gender.removeAll()
        self.eggGroup.removeAll()
        self.first.removeAll()
        self.firstName.removeAll()
        self.second.removeAll()
        self.secondName.removeAll()
        self.third.removeAll()
        self.thirdName.removeAll()
        
        Task{
            let species = try await PokemonAPI().pokemonService.fetchPokemonSpecies(num)
            
            let name = await getKoreanName(num: num)
            
          
            
            self.name = name    //이름
            
 
            if let text = species.flavorTextEntries,!text.isEmpty{    // 도감설명
                for desc in text{
                    self.desc.append(desc.flavorText ?? "")
                }
            }else{
                self.desc.append("도감 설명이 존재하지 않습니다.")
            }
            
            if let genera = species.genera{         //타이틀 - 이상해씨:씨앗포켓몬
                for gen in genera{
                    if gen.language?.name == "kor"{
                        self.genera = gen.genus ?? ""
                    }else if gen.language?.name == "en"{
                        if gen.genus == "Paradox Pokémon"{
                            self.genera = "패러독스 포켓몬"
                        }
                        
                    }
                }
            }
            
            if let gender = species.genderRate{     //성비
                if gender != -1{
                    self.gender.append((1-Double(gender)/8.0) * 100)
                    self.gender.append(Double(gender)/8.0 * 100)
                }else{
                    self.gender.append(1.0)
                }
            }
            
            if let eggGroup = species.eggGroups{    //알그룹
                for egg in eggGroup{
                    let getKoreanEgg = try await PokemonAPI().pokemonService.fetchEggGroup(urlToInt(url: egg.url!))
                    self.eggGroup.append(getKoreanEgg.names?[1].name ?? "")
                }
            }
            
            if let rate = species.captureRate{  //포획률
                self.get = rate
            }
            
            
            if let chain = species.evolutionChain?.url{     //진화트리
                let evolChain = try await PokemonAPI().evolutionService.fetchEvolutionChain(urlToInt(url: chain))   //체인
                let species = try await PokemonAPI().pokemonService.fetchPokemonSpecies(urlToInt(url: evolChain.chain?.species?.url ?? ""))
                if let name = species.names{
                    for kor in name{
                        if let korName =  kor.language?.name,korName == "ko"{
                            DispatchQueue.main.async {
                                self.firstName.append(kor.name ?? "")
                                self.first.append(self.imageUrl(url: self.urlToInt(url: evolChain.chain?.species?.url ?? "")))
                            }
                            if let vari = species.varieties{
                                for pokemon in vari{
                                    DispatchQueue.main.async {
                                        if let name = pokemon.pokemon?.name,name.hasSuffix("galar") || name.hasSuffix("alola") || name.contains("mega"){
                                            if name.hasSuffix("galar"){
                                                self.firstName.append(kor.name! + "(가라르)")
                                            }else if name.hasSuffix("alola"){
                                                self.firstName.append(kor.name! + "(알로라)" )
                                            }else if name.contains("mega"){
                                                if name.hasSuffix("mega-y"){
                                                    self.forthName.append("메가" + kor.name! + "Y")
                                                }
                                                if name.hasSuffix("mega-x"){
                                                    self.forthName.append("메가" + kor.name! + "X")
                                                }else{
                                                    self.forthName.append("메가" + kor.name!)
                                                }
                                                self.forthName = self.forthName.uniqued()
                                                self.forth.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                            }
                                            self.first.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                            self.firstName = self.firstName.uniqued()
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                }
                
                if let secondEvo = evolChain.chain?.evolvesTo{
                    for second in secondEvo{
                        let species = try await PokemonAPI().pokemonService.fetchPokemonSpecies(urlToInt(url: second.species?.url ?? ""))
                        if let name = species.names{
                            for kor in name{
                                if let korName =  kor.language?.name,korName == "ko"{
                                    DispatchQueue.main.async {
                                        self.secondName.append(kor.name ?? "")
                                        self.second.append(self.imageUrl(url: self.urlToInt(url: second.species?.url ?? "")))
                                    }
                                    if let vari = species.varieties{
                                        for pokemon in vari{
                                            DispatchQueue.main.async{
                                                if let name = pokemon.pokemon?.name,name.hasSuffix("galar") || name.hasSuffix("alola") || name.contains("mega"){
                                                    if name.hasSuffix("galar"){
                                                        self.secondName.append(kor.name! + "(가라르)")
                                                    }else if name.hasSuffix("alola"){
                                                        self.secondName.append(kor.name! + "(알로라)" )
                                                    }else if name.contains("mega"){
                                                        if name.hasSuffix("mega-y"){
                                                            self.forthName.append("메가" + kor.name! + "Y")
                                                        }
                                                        if name.hasSuffix("mega-x"){
                                                            self.forthName.append("메가" + kor.name! + "X")
                                                        }else{
                                                            self.forthName.append("메가" + kor.name!)
                                                            
                                                        }
                                                        self.forthName = self.forthName.uniqued()
                                                        self.forth.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                                    }
                                                    self.second.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                                    self.secondName = self.secondName.uniqued()
                                                }
                                                
                                            }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        
                        if let thirdEvo = second.evolvesTo{
                            for third in thirdEvo{
                                let species = try await PokemonAPI().pokemonService.fetchPokemonSpecies(urlToInt(url: third.species?.url ?? ""))
                                if let name = species.names{
                                    for kor in name{
                                        if let korName =  kor.language?.name,korName == "ko"{
                                            DispatchQueue.main.async {
                                                self.thirdName.append(kor.name ?? "")
                                                self.third.append(self.imageUrl(url: self.urlToInt(url: third.species?.url ?? "")))
                                            }
                                            if let vari = species.varieties{
                                                for pokemon in vari{
                                                    DispatchQueue.main.async {
                                                        if let name = pokemon.pokemon?.name,name.hasSuffix("galar") || name.hasSuffix("alola") || name.contains("mega"){
                                                            if name.hasSuffix("galar"){
                                                                self.thirdName.append(kor.name! + "(가라르)")
                                                            }else if name.hasSuffix("alola"){
                                                                self.thirdName.append(kor.name! + "(알로라)" )
                                                            }else if name.contains("mega"){
                                                                if name.hasSuffix("mega-y"){
                                                                    self.forthName.append("메가" + kor.name! + "Y")
                                                                }
                                                                if name.hasSuffix("mega-x"){
                                                                    self.forthName.append("메가" + kor.name! + "X")
                                                                }else{
                                                                    self.forthName.append("메가" + kor.name!)
                                                                }
                                                                self.forthName = self.forthName.uniqued()
                                                                self.forth.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                                            }
                                                            self.third.append(self.imageUrl(url: self.urlToInt(url: pokemon.pokemon?.url ?? "")))
                                                            self.thirdName = self.thirdName.uniqued()
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @MainActor
    func getPokeon(num:Int){
        
        self.hp.removeAll()
        self.attack.removeAll()
        self.defense.removeAll()
        self.spAttack.removeAll()
        self.spDefense.removeAll()
        self.speed.removeAll()
        self.avr.removeAll()
        
        self.char.removeAll()
        self.hiddenChar.removeAll()
        self.charDesc.removeAll()
        self.hiddenCharDesc.removeAll()
        
        image = imageUrl(url: num)
        
        Task{
            let types = await getKoreanType(num: num)
            self.types = types  //타입
            let pokemon = try await PokemonAPI().pokemonService.fetchPokemon(num)
            self.height = pokemon.height!   //키
            self.weight = pokemon.weight!   //몸무게
            
            
            if let stat = pokemon.stats{    //스탯
                self.hp.append(stat.first?.baseStat ?? 0)
                self.attack.append(stat[1].baseStat ?? 0)
                self.defense.append(stat[2].baseStat ?? 0)
                self.spAttack.append(stat[3].baseStat ?? 0)
                self.spDefense.append(stat[4].baseStat ?? 0)
                self.speed.append(stat.last?.baseStat ?? 0)
                self.avr.append((stat.first?.baseStat)! + stat[1].baseStat! + stat[2].baseStat! + stat[3].baseStat! + stat[4].baseStat! + (stat.last?.baseStat)!)
            }
            if let ability = pokemon.abilities{ //특성
                for ab in ability{
                    if let hidden = ab.isHidden{
                        if hidden{
                            let getKoreanAbility = try await PokemonAPI().pokemonService.fetchAbility(urlToInt(url: ab.ability?.url ?? ""))
                            if let names = getKoreanAbility.names{
                                for name in names{
                                    if name.language?.name == "ko"{
                                        self.hiddenChar.append(name.name ?? "")
                                    }
                                }
                            }
                            if let getKor = getKoreanAbility.flavorTextEntries{
                                for i in getKor{
                                    if i.language?.name == "ko"{
                                        self.hiddenCharDesc.append(i.flavorText ?? "")
                                        
                                    }
                                }
                            }
                        }else{
                            let getKoreanAbility = try await PokemonAPI().pokemonService.fetchAbility(urlToInt(url: ab.ability?.url ?? ""))
                            if  let names = getKoreanAbility.names{
                                for name in names{
                                    if name.language?.name == "ko"{
                                        self.char.append(name.name ?? "")
                                        
                                    }else{
                                        if name.name == "Quark Drive"{
                                            self.char.append("쿼크차지")
                                        }
                                    }
                                }
                            }
                            if let getKor = getKoreanAbility.flavorTextEntries,!getKor.isEmpty{
                                for i in getKor{
                                    if i.language?.name == "ko"{
                                        self.charDesc.append(i.flavorText ?? "")
                                    }
                                }
                            }else{
                                self.charDesc.append("부스트에너지를 지니고 있거나 일렉트릭필드일 때 가장 높은 능력이 올라간다.")
                            }
                            
//                            print(char)
//                            print(charDesc)
                        }
                        hiddenChar.removeAll{char.contains($0)}
                    }
                }
            }
        }
        
    }
    @MainActor
    func getregional(num:Int){
        Task{
            let species = try await PokemonAPI().pokemonService.fetchPokemonSpecies(num)
            if let vari = species.varieties{
                guard vari.count > 1 else { return }
                for isRegion in vari{
                   
                    self.isRegion.append(urlToInt(url: isRegion.pokemon?.url ?? ""))
                    let another = try await PokemonAPI().pokemonService.fetchPokemon(urlToInt(url: isRegion.pokemon?.url ?? ""))
                    if let forms = another.forms{
                        for form in forms{
                            let pokemonForm = try await PokemonAPI().pokemonService.fetchPokemonForm(urlToInt(url: form.url ?? ""))
                            if pokemonForm.formName == ""{
                                self.isRegionName.append("기본")
                            }
                            if let names = pokemonForm.formNames{
                                for i in names{
                                    if i.language?.name == "ko"{
                                        self.isRegionName.append(i.name ?? "")
                                    }
                                    
                                }
                                
                                if pokemonForm.formName == "rock-star"{
                                    self.isRegionName.append("하드록")
                                }else if pokemonForm.formName == "starter"{
                                    self.isRegionName.append("스타터")
                                }
                                else if pokemonForm.formName == "belle"{
                                    self.isRegionName.append("마담")
                                }
                                else if pokemonForm.formName == "pop-star"{
                                    self.isRegionName.append("아이돌")
                                }
                                else if pokemonForm.formName == "phd"{
                                    self.isRegionName.append("닥터")
                                }
                                else if pokemonForm.formName == "libre"{
                                    self.isRegionName.append("마스크드")
                                }
                                else if pokemonForm.formName == "cosplay"{
                                    self.isRegionName.append("코스튬플레이")
                                }
                                else if pokemonForm.formName == "gmax"{
                                    self.isRegionName.append("거다이맥스")
                                }
//                                print(self.isRegion)
//                                print(self.isRegionName)
                            }
                        }
                    }
                }
            }
        }
    }
}
